//
//  LoginViewController.m
//  StudySpot
//
//  Created by Matthew Werner on 2/9/14.
//  Copyright (c) 2014 Cal Poly. All rights reserved.
//

#import "LoginViewController.h"
#import "ProfileViewController.h"
#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>
#import <WindowsAzureMobileServices/WindowsAzureMobileServices.h>

@interface LoginViewController ()

@property (nonatomic, strong) NSString *kClientId;
@property (nonatomic, strong) GPPSignIn *signIn;
@property (nonatomic, strong) MSClient *client;
@property (nonatomic, strong) UIActivityIndicatorView *av;

@end

@implementation LoginViewController

/* Unwind segue that occurs when user logs out of google plus account */
- (IBAction)unwindToLogin:(UIStoryboardSegue *)segue
{
    [[GPPSignIn sharedInstance] disconnect];
}

- (void)didDisconnectWithError:(NSError *)error
{
    if (error)
    {
        NSLog(@"Received error %@", error);
    }
    else
    {
        // The user is signed out and disconnected.
    }
}

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
    
    // Google Plus API client ID
    self.kClientId = @"116494545247-0bg0fesmf8qum58q3diimr5ra7q2546c.apps.googleusercontent.com";
    
    // Set properties of Google Plus sign in
    _signIn = [GPPSignIn sharedInstance];
    _signIn.shouldFetchGooglePlusUser = YES;
    _signIn.shouldFetchGoogleUserEmail = YES;
    _signIn.clientID = self.kClientId;
    _signIn.scopes = @[@"profile"];
    _signIn.delegate = self;
    
    // Initialize Azure Mobile Service Client
    self.client = [MSClient clientWithApplicationURLString:@"https://studyspot.azure-mobile.net/"
                                            applicationKey:@"UeeXTmfsscRIhhVuCyRqDRwfThBDPa90"];
    
}

/* Adds first time logged in user to Azure DB */
- (void)addUserToDB:(ProfileViewController *)vc
                   :(MSTable *)userTable
{
    // Initialize stuff for Google Plus query to get user info
    GTLServicePlus *plusService = [[GTLServicePlus alloc] init];
    plusService.retryEnabled = YES;
    [plusService setAuthorizer:[GPPSignIn sharedInstance].authentication];
    GTLQueryPlus *query = [GTLQueryPlus queryForPeopleGetWithUserId:@"me"];
    
    // Run query to get user info such as first and last name
    [plusService executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLPlusPerson *person, NSError *error)
    {
        if (error)
        {
            GTMLoggerError(@"Error: %@", error);
        }
        else
        {
            // Create new item to be inserted into Azure DB
            NSDictionary *newItem = @{@"firstname": person.name.givenName,
                                      @"lastname": person.name.familyName, @"email": vc.email, @"u_school_id": @1};
                    
            // Insert new user item into Azure DB
            [userTable insert:newItem completion:^(NSDictionary *item, NSError *error)
            {
                UIActivityIndicatorView *tmpimg = (UIActivityIndicatorView *)[self.view viewWithTag:1];
                [tmpimg removeFromSuperview];
                [self.navigationController pushViewController:vc animated:YES];
            }];
        }
    }];
}

/* Runs query to see if currently logged in user is already in Azure DB.
   If the user is already logged in, segue to ProfileViewController.
   Otherwise, add new user to DB. */
- (void)initializeUser:(ProfileViewController *)vc
{
    MSTable *userTable = [self.client tableWithName:@"users"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"email == %@", vc.email];
    
    // Query users table for logged in user
    [userTable readWithPredicate:predicate completion:^(NSArray *items, NSInteger totalCount, NSError *error)
    {
        if (error)
        {
            NSLog(@"ERROR %@", error);
        }
        // User not found in users table.  First time logging in.
        else if ([items count] == 0)
        {
            [self addUserToDB:vc :userTable];
        }
        // User already in users table.  Segue without adding user to users table.
        else
        {
            UIActivityIndicatorView *tmpimg = (UIActivityIndicatorView *)[self.view viewWithTag:1];
            [tmpimg removeFromSuperview];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }];
}

/* Segues to profile screen if user successfully logs in via Google Plus.
   Adds user to Azure DB if it's the user's first login. */
- (void)segueBasedOnSignIn
{
    _av = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    _av.frame = CGRectMake(160, 350, 2, 25);
    _av.tag = 1;
    [self.view addSubview:_av];
    [_av startAnimating];
    
    // User log in successful
    if ([[GPPSignIn sharedInstance] authentication])
    {
        NSString * storyboardName = @"Main";
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
        
        // Pass user's e-mail to ProfileViewController
        ProfileViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"ProfileViewController"];
        vc.email = _signIn.authentication.userEmail;
        
        // Add user to Azure DB if not already
        [self initializeUser:vc];
        
    }
    else
    {
        NSLog(@"User not signed in");
    }
}


- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error
{
    if (error)
    {
        // Log error
        NSLog(@"Receieved error %@ and auth object %@", error, auth);
    }
    else
    {
        [self segueBasedOnSignIn];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    printf("Segue ID: %s\n", [identifier UTF8String]);
    
    return YES;
}

@end
