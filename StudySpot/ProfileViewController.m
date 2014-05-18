//
//  ProfileViewController.m
//  StudySpot
//
//  Created by Matthew Werner on 2/9/14.
//  Copyright (c) 2014 Cal Poly. All rights reserved.
//

#import "ProfileViewController.h"
#import "EditCoursesViewController.h"
#import "StudySpotsViewController.h"
#import <WindowsAzureMobileServices/WindowsAzureMobileServices.h>

@interface ProfileViewController ()

@property (nonatomic, strong) MSClient *client;
@property (nonatomic, strong) NSMutableArray *enrolledCourses;
@property (nonatomic, strong) NSNumber *userID;

@end

@implementation ProfileViewController

/* Unwind segue that occurs when user finishes editing courses */
- (IBAction)unwindToProfile:(UIStoryboardSegue *)segue
{
    /* Do nothing */
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    
    return self;
}

/* Queries the Azure DB to get the current user's school name */
- (void)fillSchoolLabel
{
    MSTable *usrSchoolView = [self.client tableWithName:@"vw_users_schools"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"email == %@", self.email];
    
    [usrSchoolView readWithPredicate:predicate completion:^(NSArray *items, NSInteger totalCount, NSError *error)
    {
        if (error)
        {
            NSLog(@"ERROR %@", error);
        }
        else if (totalCount == 0)
        {
            NSLog(@"No results matching e-mail: %@", self.email);
        }
        else
        {
            // There should only be 1 row returned with an email matching the current user's email
            for (NSDictionary *item in items)
            {
                self.schoolLabel.text = [item objectForKey:@"schoolname"];
            }
        }
    }];
}

/* Queries Azure DB to get user info and set UILables appropriately */
- (void)populateLabels
{
    MSTable *userTable = [self.client tableWithName:@"users"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"email == %@", self.email];
    
    [userTable readWithPredicate:predicate completion:^(NSArray *items, NSInteger totalCount, NSError *error)
     {
         if (error)
         {
             NSLog(@"ERROR %@", error);
         }
         else if (totalCount == 0)
         {
             NSLog(@"No results matching e-mail: %@", self.email);
         }
         else
         {
             // There should only be 1 row returned with an email matching the current user's email
             for (NSDictionary *item in items)
             {
                 // Populate the appropriate labels of the user's profile
                 self.emailLabel.text = [item objectForKey:@"email"];
                 self.firstNameLabel.text = [item objectForKey:@"firstname"];
                 self.lastNameLabel.text = [item objectForKey:@"lastname"];
                 
                 // Call method to run query and fill in school name label
                 [self fillSchoolLabel];
             }
         }
     }];
}

/* Query the Azure DB for the course data for all courses the current user is enrolled in.
   The results are stored into an array and the table view is reloaded to reflect the user's
   current list of enrolled courses. */
- (void)storeCourses:(NSArray *)items
{
    NSMutableString *predicateString = [[NSMutableString alloc] init];
    
    /* Create DB query "where" clause that looks for all courses where the course ID matches one from the
       user_courses table query */
    for (int i=0; i<items.count; i++)
    {
        if (i < items.count - 1)
        {
            [predicateString appendString: [NSString stringWithFormat:@"id == %@ OR ", [items[i] objectForKey:@"uc_courseid"]]];
        }
        else
        {
            [predicateString appendString:[NSString stringWithFormat:@"id == %@", [items[i] objectForKey:@"uc_courseid"]]];
        }
    }
    
    if ([predicateString length] != 0)
    {
        /* Create object to access the course table */
        MSTable *courseTable = [self.client tableWithName:@"courses"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];

        [courseTable readWithPredicate:predicate completion:^(NSArray *items, NSInteger totalCount, NSError *error) {
            if (error)
            {
                NSLog(@"ERROR %@", error);
            }
            else
            {
                /* Add user enrolled courses to a mutable array */
                for (NSDictionary *item in items)
                {
                    [self.enrolledCourses addObject:item];
                }
                
                /* Update table view to accurately reflect */
                [self.enrolledTable reloadData];
            }
        }];
    }
}

/* This method queries the Azure DB and gets a list of the rows with the user's ID and course IDs */
- (void)queryUserCourses
{
    /* Create object to access the user_course table */
    MSTable *userCourseTable = [self.client tableWithName:@"user_course"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uc_userid == %@", self.userID];
    
    [userCourseTable readWithPredicate:predicate completion:^(NSArray *items, NSInteger totalCount, NSError *error) {
        if (error)
        {
            NSLog(@"ERROR %@", error);
        }
        else
        {
            /* Query for the user's course data from the Courses table */
            [self storeCourses:items];
        }
    }];
}

/* This method queries the DB to determine the courses the logged-in user is currently enrolled in */
- (void)loadEnrolledCourses
{
    /* Create object to access the user table */
    MSTable *userTable = [self.client tableWithName:@"users"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"email == %@", self.email];
    
    // Query users table for logged in user
    [userTable readWithPredicate:predicate completion:^(NSArray *items, NSInteger totalCount, NSError *error)
     {
         if (error)
         {
             NSLog(@"ERROR %@", error);
         }
         else if (totalCount == 0)
         {
             NSLog(@"No results matching e-mail: %@", self.email);
         }
         else
         {
             // There should only be 1 row returned. Get user ID of logged in user
             for (NSDictionary *item in items)
             {
                 self.userID = [NSNumber numberWithInt:[[item objectForKey:@"id"] intValue]];
             }
             
             /* Get the course IDs for the courses the user is enrolled in */
             [self queryUserCourses];
         }
     }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize Azure Mobile Service Client
    self.client = [MSClient clientWithApplicationURLString:@"https://studyspot.azure-mobile.net/"
                                        applicationKey:@"UeeXTmfsscRIhhVuCyRqDRwfThBDPa90"];
    
    self.enrolledCourses = [[NSMutableArray alloc] init];
    
    [self populateLabels];
    //[self loadEnrolledCourses];
}

/* Called when returning from Edit Courses screen */
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.enrolledCourses removeAllObjects];
    [self loadEnrolledCourses];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/* Runs when "Edit Courses" button selected. Pushes edit courses view onto nav stack */
- (IBAction)editCourses:(id)sender
{
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    
    // Pass user's e-mail to EditCoursesViewController
    EditCoursesViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"EditCoursesViewController"];
    vc.email = self.email;
    
    [self.navigationController pushViewController:vc animated:YES];
}

/* Runs when "Study Spots" nav button selected. Pushes study spots view onto nav stack */
- (IBAction)studySpots:(id)sender
{
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    
    // Pass user's e-mail to StudySpotViewController
    StudySpotsViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"StudySpotsViewController"];
    vc.email = self.email;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

/* Determines number of rows in table view */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.enrolledCourses count];
}

/* Populates table view cells with enrolled courses info */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont fontWithName:@"Futura" size:18.0];
    cell.textLabel.text = [[self.enrolledCourses objectAtIndex:indexPath.row] objectForKey:@"course"];
    
    return cell;
}

@end
