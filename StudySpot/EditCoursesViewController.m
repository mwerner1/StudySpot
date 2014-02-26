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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // Initialize Azure Mobile Service Client
    self.client = [MSClient clientWithApplicationURLString:@"https://studyspot.azure-mobile.net/"
                                            applicationKey:@"UeeXTmfsscRIhhVuCyRqDRwfThBDPa90"];
    
    self.enrolledCourses = [[NSMutableArray alloc] init];
    
    [self loadDepartments];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.enrolledCourses count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text =
}

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
    NSNumber *courseID = [NSNumber numberWithInt:[[[self.courseNums objectAtIndex:row] objectForKey:@"id"] integerValue]];
    
    NSLog(@"FOO BAR: %@", [self.courseNums objectAtIndex:row]);
    
    if ([self.enrolledCourses containsObject:courseID])
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
        [self.enrolledCourses addObject:courseID];
    
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
