//
//  StudySpotsViewController.m
//  StudySpot
//
//  Created by Matthew Werner on 3/3/14.
//  Copyright (c) 2014 Cal Poly. All rights reserved.
//

#import "StudySpotsViewController.h"
#import "CreateSSViewController.h"
#import <WindowsAzureMobileServices/WindowsAzureMobileServices.h>

@interface StudySpotsViewController ()

@property (nonatomic, strong) MSClient *client;
@property (nonatomic, strong) NSMutableArray *enrolledCourses;
@property (nonatomic, strong) NSArray *studySpotList;
@property (nonatomic, strong) UIPickerView *filterPicker;
@property (nonatomic, strong) UITextField *pickerTextField;
@property (nonatomic, strong) NSNumber *userID;
@property (nonatomic, strong) NSIndexPath *indexPth;

@end

@implementation StudySpotsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

/* Unwind segue that occurs when user finishes editing new Study Spot */
- (IBAction)unwindToStudySpots:(UIStoryboardSegue *)segue
{
    /* Do nothing */
}

- (IBAction)filterStudySpots:(id)sender
{
    _pickerTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_pickerTextField];
    
    UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
    keyboardDoneButtonView.barStyle = UIBarStyleBlack;
    keyboardDoneButtonView.translucent = YES;
    keyboardDoneButtonView.tintColor = nil;
    [keyboardDoneButtonView sizeToFit];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(doneClicked:)];
    
    UIBarButtonItem *btnSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(cancelClicked:)];
    
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:doneButton, btnSpace, cancelButton, nil]];
    
    
    
    _pickerTextField.inputView = _filterPicker;
    _pickerTextField.inputAccessoryView = keyboardDoneButtonView;
    
    [_pickerTextField becomeFirstResponder];
    
}

- (void)doneClicked:(id)sender
{
    NSInteger row = [self.filterPicker selectedRowInComponent:0];
    
    [self filter:row];
    
    [_pickerTextField resignFirstResponder];
}

- (void)cancelClicked:(id)sender
{
    [_pickerTextField resignFirstResponder];
}

- (void)filter:(NSInteger)row
{
    MSTable *sSUsrsCrsView = [self.client tableWithName:@"vw_studyspot_courses_users"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"course == %@", [[self.enrolledCourses objectAtIndex:row] objectForKey:@"course"]];
    
    [sSUsrsCrsView readWithPredicate:predicate completion:^(NSArray *items, NSInteger totalCount, NSError *error) {
        if (error)
        {
            NSLog(@"ERROR %@", error);
        }
        else if (totalCount == 0)
        {
            NSLog(@"Course not found");
        }
        else
        {
            [self studySpotLoadComplete:items];
        }
    }];
}

- (void)studySpotLoadComplete:(NSArray *)studySpots
{
    self.studySpotList = studySpots;
    
    [self.studySpotTable reloadData];
}

- (void)loadStudySpots
{
    MSTable *sSUsrsCrsView = [self.client tableWithName:@"vw_studyspot_courses_users"];
    
    [sSUsrsCrsView readWithCompletion:^(NSArray *items, NSInteger totalCount, NSError *error) {
        if (error)
        {
            NSLog(@"ERROR %@", error);
        }
        else
        {
            [self studySpotLoadComplete:items];
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
	
    [self loadStudySpots];
    
    _filterPicker = [[UIPickerView alloc] init];
    [_filterPicker setDataSource: self];
    [_filterPicker setDelegate: self];
    _filterPicker.showsSelectionIndicator = YES;
    
    [self loadEnrolledCourses];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadStudySpots];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/* Determines number of rows in enrolled courses picker view */
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.enrolledCourses count];
}

/* Populates rows of enrolled courses picker view */
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [NSString stringWithFormat:@"%@", [[self.enrolledCourses objectAtIndex:row] objectForKey:@"course"]];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

/* Determines number of rows in table view */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.studySpotList count];
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
    
    cell.textLabel.font = [UIFont fontWithName:@"Futura" size:14.0];
    cell.textLabel.lineBreakMode = NSLineBreakByClipping;
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.text = [NSString stringWithFormat:@"%@\t\t\t%@\n%@ - %@",
                           [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"course"],
                           [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"startdate"],
                           [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"starttime"],
                           [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"endtime"]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _indexPth = indexPath;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Study Spot Info"
                                                    message: [NSString stringWithFormat:@"Creator: %@ %@\nEmail: %@\nCourse: %@\nDate: %@\nTime: %@ - %@\nLocation: %@", [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"firstname"], [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"lastname"], [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"email"], [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"course"], [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"startdate"], [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"starttime"], [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"endtime"],
                                                        [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"location"]]
                                                   delegate: self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:@"Attendees", @"Join", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSNumber *ssID = [[self.studySpotList objectAtIndex:_indexPth.row] objectForKey:@"ss_id"];
    
    MSTable *userStudySpotTable = [self.client tableWithName:@"users_studyspot"];
    
    if (buttonIndex == [alertView firstOtherButtonIndex])
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"us_ssid == %@", ssID];
        [userStudySpotTable readWithPredicate:predicate completion:^(NSArray *items, NSInteger totalCount, NSError *error) {
            if (error)
            {
                NSLog(@"ERROR %@", error);
            }
            else
            {
                NSMutableString *predStr = [[NSMutableString alloc] initWithString:@""];
                NSMutableString *attendeeNames = [[NSMutableString alloc] initWithString:@""];
                
                for (int i=0; i<items.count; i++)
                {
                    if (i == items.count-1)
                    {
                        [predStr appendString:[NSString stringWithFormat:@"id == %@",
                                               [[items objectAtIndex:i] objectForKey:@"us_userid"]]];
                    }
                    else
                    {
                        [predStr appendString:[NSString stringWithFormat:@"id == %@ || ",
                                               [[items objectAtIndex:i] objectForKey:@"us_userid"]]];
                    }
                }
                
                MSTable *usersTable = [self.client tableWithName:@"users"];
                NSPredicate *pred = [NSPredicate predicateWithFormat:predStr];
                
                [usersTable readWithPredicate:pred completion:^(NSArray *items, NSInteger totalCount, NSError *error) {
                    if (error)
                    {
                        NSLog(@"ERROR %@", error);
                    }
                    else
                    {
                        for (NSDictionary *item in items)
                        {
                            [attendeeNames appendString:[NSString stringWithFormat:@"%@ %@\n",
                                                         [item objectForKey:@"firstname"], [item objectForKey:@"lastname"]]];
                        }
                        
                        UIAlertView *attendeesAlert = [[UIAlertView alloc] initWithTitle:@"Study Spot Attendees"
                                                                                 message:attendeeNames
                                                                                delegate:nil
                                                                       cancelButtonTitle:@"OK"
                                                                       otherButtonTitles:nil];
                        
                        [attendeesAlert show];
                    }
                }];
            }
        }];
    }
    else if (buttonIndex == 2)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"us_ssid == %@ && us_userid == %@", ssID, _userID];
        
        [userStudySpotTable readWithPredicate:predicate completion:^(NSArray *items, NSInteger totalCount, NSError *error) {
            if (items.count == 0)
            {
                NSDictionary *newUsrSS = @{@"us_ssid":ssID, @"us_userid":_userID, @"us_status":@1};
                
                [userStudySpotTable insert:newUsrSS completion:^(NSDictionary *item, NSError *error) {
                    if (error)
                    {
                        NSLog(@"ERROR %@", error);
                    }
                }];
            }
        }];
    }
}

- (IBAction)createStudySpots:(id)sender
{
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    
    // Pass user's e-mail to StudySpotViewController
    CreateSSViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"CreateSSViewController"];
    vc.email = self.email;
    
    [self.navigationController pushViewController:vc animated:YES];
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
                     
                     if ([predicateString length] != 0)
                     {
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
                                 
                                 [self.filterPicker reloadAllComponents];
                             }
                         }];
                     }
                 }
             }];
         }
     }];
}

@end
