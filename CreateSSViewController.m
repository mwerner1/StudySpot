//
//  CreateSSViewController.m
//  StudySpot
//
//  Created by Matthew Werner on 4/5/14.
//  Copyright (c) 2014 Cal Poly. All rights reserved.
//

#import "CreateSSViewController.h"
#import "StudySpotsViewController.h"
#import <WindowsAzureMobileServices/WindowsAzureMobileServices.h>

@interface CreateSSViewController ()

@property (nonatomic, strong) MSClient *client;
@property (nonatomic, strong) NSNumber *userID;
@property (nonatomic, strong) NSMutableArray *enrolledCourses;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UIPickerView *coursePicker;
@property (nonatomic, strong) NSDate *startDateTime;
@property (nonatomic, strong) NSDate *endDateTime;

@end

@implementation CreateSSViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    // Initialize Azure Mobile Service Client
    self.client = [MSClient clientWithApplicationURLString:@"https://studyspot.azure-mobile.net/"
                                            applicationKey:@"UeeXTmfsscRIhhVuCyRqDRwfThBDPa90"];
    
    self.enrolledCourses = [[NSMutableArray alloc] init];
    
    _coursePicker = [[UIPickerView alloc] init];
    [_coursePicker setDataSource: self];
    [_coursePicker setDelegate: self];
    _coursePicker.showsSelectionIndicator = YES;
    
    
    [self loadEnrolledCourses];
    
    UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
    keyboardDoneButtonView.barStyle = UIBarStyleBlack;
    keyboardDoneButtonView.translucent = YES;
    keyboardDoneButtonView.tintColor = nil;
    [keyboardDoneButtonView sizeToFit];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                  action:@selector(doneClicked:)];
    
    
    _datePicker = [[UIDatePicker alloc] init];
    _datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    [_datePicker addTarget:self action:nil forControlEvents:UIControlEventValueChanged];
    
    
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:doneButton, nil]];
    
    self.addCourseTextField.inputView = _coursePicker;
    self.addCourseTextField.inputAccessoryView = keyboardDoneButtonView;
    
    self.addStartTextField.inputView = _datePicker;
    self.addStartTextField.inputAccessoryView = keyboardDoneButtonView;
    
    self.addEndTextField.inputView = _datePicker;
    self.addEndTextField.inputAccessoryView = keyboardDoneButtonView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)doneClicked:(id)sender
{
    NSDate *date = [[NSDate alloc] init];
    date = _datePicker.date;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle:NSDateFormatterMediumStyle];
    [df setTimeStyle:NSDateFormatterMediumStyle];
    [df setLocale:[NSLocale currentLocale]];
    [df setDateFormat:@"MM-dd-yyyy 'at' h:mm a"];
    
    
    if ([self.addStartTextField isFirstResponder])
    {
        _startDateTime = [date dateByAddingTimeInterval:60*60] ;
        [self.addStartTextField setText:[df stringFromDate:date]];
        [self.addStartTextField resignFirstResponder];
    }
    else if ([self.addEndTextField isFirstResponder])
    {
        _endDateTime = [date dateByAddingTimeInterval:60*60];
        [self.addEndTextField setText:[df stringFromDate:date]];
        [self.addEndTextField resignFirstResponder];
    }
    else
    {
        [self.addCourseTextField setText:[[self.enrolledCourses objectAtIndex:[_coursePicker selectedRowInComponent:0]] objectForKey:@"course"]];
        [self.addCourseTextField resignFirstResponder];
    }
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
        
                                 [self.coursePicker reloadAllComponents];
                             }
                         }];
                     }
                 }
             }];
         }
     }];
}

/* Determines number of rows in enrolled courses picker view */
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.enrolledCourses count];
}

/* Populates rows of enrolled courses picker view */
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    //NSLog(@"Foo: %@", [[self.enrolledCourses objectAtIndex:row] objectForKey:@"course"]);
    return [NSString stringWithFormat:@"%@", [[self.enrolledCourses objectAtIndex:row] objectForKey:@"course"]];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (IBAction)saveSSButton:(id)sender
{
    if ([self.addStartTextField.text isEqualToString:@""] || [self.addEndTextField.text isEqualToString:@""] ||
        [self.addCourseTextField.text isEqualToString:@""] || [self.addLocationTextView.text isEqualToString:@""])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Missing Fields"
                                                        message:@"Please Fill in All Study Spot Fields"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
    }
    else
    {
        [self saveStudySpot];
    }
}

- (void)saveStudySpot
{
    MSTable *courseTable = [self.client tableWithName:@"courses"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"course == %@", [self.addCourseTextField text]];
    
    [courseTable readWithPredicate:predicate completion:^(NSArray *items, NSInteger totalCount, NSError *error) {
        if (error)
        {
            NSLog(@"ERROR %@", error);
        }
        else
        {
            MSTable *studySpotTable = [self.client tableWithName:@"studyspot"];
            
            for (NSDictionary *item in items)
            {
                
                NSDictionary *newStudySpot = @{@"ss_school_id":@1, @"ss_course_id":[item objectForKey:@"id"],
                                               @"ss_startdatetime":_startDateTime,
                                                                    @"ss_enddatetime":_endDateTime,
                                               @"ss_creator":self.userID, @"ss_status":@1, @"location":[self.addLocationTextView text]};
                
                [studySpotTable insert:newStudySpot completion:^(NSDictionary *item, NSError *error) {
                    if (error)
                    {
                        NSLog(@"ERROR %@", error);
                    }
                    else
                    {
                        MSTable *usersStudySpotTable = [self.client tableWithName:@"users_studyspot"];
                        
                        NSDictionary *newUsrSS = @{@"us_ssid":[item objectForKey:@"id"], @"us_userid":_userID, @"us_status":@1};
                        
                        [usersStudySpotTable insert:newUsrSS completion:^(NSDictionary *item, NSError *error) {
                            if (error)
                            {
                                NSLog(@"ERROR %@", error);
                            }
                            else
                            {
                                NSString * storyboardName = @"Main";
                                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
                                
                                // Pass user's e-mail to StudySpotViewController
                                StudySpotsViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"StudySpotsViewController"];
                                vc.email = self.email;
                                
                                [self.navigationController pushViewController:vc animated:YES];
                            }
                        }];
                    }
                }];
            }
            
        }
    }];
}

@end