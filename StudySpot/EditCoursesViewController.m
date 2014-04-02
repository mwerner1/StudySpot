//
//  EditCoursesViewController.m
//  StudySpot
//
//  Created by Matthew Werner on 2/23/14.
//  Copyright (c) 2014 Cal Poly. All rights reserved.
//

#import "EditCoursesViewController.h"
#import <WindowsAzureMobileServices/WindowsAzureMobileServices.h>

@interface EditCoursesViewController ()

@property (nonatomic, strong) MSClient *client;
@property (nonatomic, strong) NSArray *deptAbbrevs;
@property (nonatomic, strong) NSArray *courseNums;
@property (nonatomic, strong) NSMutableArray *enrolledCourses;
@property (nonatomic, strong) NSNumber *userID;

@end

@implementation EditCoursesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)crsLoadComplete:(NSArray *)abbrevs
{
    self.deptAbbrevs = abbrevs;
    [self.dept reloadAllComponents];
    
    [self loadCourseNums:[self.deptAbbrevs[0] objectForKey:@"crsabbrev"]];
}

- (void)crsNumsLoadComplete:(NSArray *)crsNums
{
    self.courseNums = crsNums;
    [self.courseNum reloadAllComponents];
}

- (void)loadDepartments
{
    MSTable *coursesView = [self.client tableWithName:@"vw_distinct_courseabbrev"];
    
    [coursesView readWithCompletion:^(NSArray *items, NSInteger totalCount, NSError *error) {
        if(error)
        {
            NSLog(@"ERROR %@", error);
        }
        else
        {
            [self crsLoadComplete:items];
        }
    }];
}

- (void)loadCourseNums:(NSString *)abbrev
{
    MSTable *coursesTable = [self.client tableWithName:@"courses"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"crsabbrev == %@", abbrev];
    
    [coursesTable readWithPredicate:predicate completion:^(NSArray *items, NSInteger totalCount, NSError *error) {
        if (error)
        {
            NSLog(@"ERROR %@", error);
        }
        else
        {
            [self crsNumsLoadComplete:items];
        }
    }];
}

- (void)loadEnrolledCourses
{
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
             // There should only be 1 row returned with an email matching the current user's email
             for (NSDictionary *item in items)
             {
                 self.userID = [NSNumber numberWithInt:[[item objectForKey:@"id"] intValue]];
             }
             
             MSTable *userCourseTable = [self.client tableWithName:@"user_course"];
             NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uc_userid == %@", self.userID];
             
             [userCourseTable readWithPredicate:predicate completion:^(NSArray *items, NSInteger totalCount, NSError *error) {
                 if (error)
                 {
                     NSLog(@"ERROR %@", error);
                 }
                 else
                 {
                     NSMutableString *predicateString = [[NSMutableString alloc] init];
                     
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
                     
                     MSTable *courseTable = [self.client tableWithName:@"courses"];
                     NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
                     
                     [courseTable readWithPredicate:predicate completion:^(NSArray *items, NSInteger totalCount, NSError *error) {
                         if (error)
                         {
                             NSLog(@"ERROR %@", error);
                         }
                         else
                         {
                             for (NSDictionary *item in items)
                             {
                                 [self.enrolledCourses addObject:item];
                             }
                             
                             [self.coursesTable reloadData];
                         }
                     }];
                 }
             }];
         }
     }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // Initialize Azure Mobile Service Client
    self.client = [MSClient clientWithApplicationURLString:@"https://studyspot.azure-mobile.net/"
                                            applicationKey:@"UeeXTmfsscRIhhVuCyRqDRwfThBDPa90"];
    
    self.enrolledCourses = [[NSMutableArray alloc] init];
    
    [self loadDepartments];
    [self loadEnrolledCourses];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        MSTable *userCourseTable = [self.client tableWithName:@"user_course"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uc_userid == %@ AND uc_courseid == %@", self.userID, [[self.enrolledCourses objectAtIndex:indexPath.row] objectForKey:@"id"]];
        
        [userCourseTable readWithPredicate:predicate completion:^(NSArray *items, NSInteger totalCount, NSError *error) {
            if (error)
            {
                NSLog(@"ERROR %@", error);
            }
            else
            {
                for (NSDictionary *item in items)
                {
                    [userCourseTable delete:item completion:^(id itemId, NSError *error) {
                        if (error)
                        {
                            NSLog(@"ERROR %@", error);
                        }
                        else
                        {
                            // Successful Delete
                            [self.enrolledCourses removeObjectAtIndex:indexPath.row];
                            [self.coursesTable reloadData];
                        }
                    }];
                }
            }
        }];
    }
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

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

/* Populates table view cells with course info */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = [[self.enrolledCourses objectAtIndex:indexPath.row] objectForKey:@"course"];
    
    return cell;
}

/* Determines number of rows in department and course num picker views */
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == self.dept)
    {
        return [self.deptAbbrevs count];
    }
    else
    {
        return [self.courseNums count];
    }
}

/* Populates rows of department and course num picker views with appropriate values */
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (pickerView == self.dept)
    {
        return [NSString stringWithFormat:@"%@", [[self.deptAbbrevs objectAtIndex:row] objectForKey:@"crsabbrev"]];
    }
    else
    {
        return [NSString stringWithFormat:@"%@", [[self.courseNums objectAtIndex:row] objectForKey:@"crsnum"]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (pickerView == self.dept)
    {
        [self loadCourseNums:[[self.deptAbbrevs objectAtIndex:row] objectForKey:@"crsabbrev"]];
    }
}

- (void)addCourseToDB
{
    NSInteger row = [self.courseNum selectedRowInComponent:0];
    
    if ([self.enrolledCourses containsObject:[self.courseNums objectAtIndex:row]])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Oops!"
                                                        message: @"You are already enrolled in that course."
                                                       delegate: nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        [self.enrolledCourses addObject:[self.courseNums objectAtIndex:row]];
    
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
                 NSString *userID;
                 NSNumber *courseID = [NSNumber numberWithInt:[[[self.courseNums objectAtIndex:row] objectForKey:@"id"] integerValue]];
                 MSTable *userCourseTable = [self.client tableWithName:@"user_course"];
                 
                 // There should only be 1 row returned with an email matching the current user's email
                 for (NSDictionary *item in items)
                 {
                     userID = [item objectForKey:@"id"];
                 }
                 
                 // Create new item to be inserted into Azure DB
                 NSDictionary *newItem = @{@"uc_userid": [NSNumber numberWithInt:[userID intValue]],
                                           @"uc_courseid": courseID};
                 
                 // Insert new user/course item into Azure DB
                 [userCourseTable insert:newItem completion:^(NSDictionary *item, NSError *error)
                  {
                      if (error)
                      {
                          NSLog(@"ERROR %@", error);
                      }
                      else
                      {
                          [self.coursesTable reloadData];
                      }
                  }];
             }
         }];
    }
}

- (IBAction)addCourseButton:(id)sender
{
    [self addCourseToDB];
}
@end
