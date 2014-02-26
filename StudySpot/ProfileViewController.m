//
//  ProfileViewController.m
//  StudySpot
//
//  Created by Matthew Werner on 2/9/14.
//  Copyright (c) 2014 Cal Poly. All rights reserved.
//

#import "ProfileViewController.h"
#import "EditCoursesViewController.h"
#import <WindowsAzureMobileServices/WindowsAzureMobileServices.h>

@interface ProfileViewController ()

@property (nonatomic, strong) MSClient *client;

@end

@implementation ProfileViewController

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize Azure Mobile Service Client
    self.client = [MSClient clientWithApplicationURLString:@"https://studyspot.azure-mobile.net/"
                                        applicationKey:@"UeeXTmfsscRIhhVuCyRqDRwfThBDPa90"];
    
    [self populateLabels];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/* Runs when "Edit Courses" button selected */
- (IBAction)editCourses:(id)sender
{
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    
    // Pass user's e-mail to EditCoursesViewController
    EditCoursesViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"EditCoursesViewController"];
    vc.email = self.email;
    
    [self.navigationController pushViewController:vc animated:YES];
}

@end
