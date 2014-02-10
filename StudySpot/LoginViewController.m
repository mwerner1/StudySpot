//
//  LoginViewController.m
//  StudySpot
//
//  Created by Matthew Werner on 2/9/14.
//  Copyright (c) 2014 Cal Poly. All rights reserved.
//

#import "LoginViewController.h"
#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>

@interface LoginViewController ()

@end

@implementation LoginViewController

static NSString * const kClientId = @"116494545247-0bg0fesmf8qum58q3diimr5ra7q2546c.apps.googleusercontent.com";

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
    
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.shouldFetchGooglePlusUser = YES;
    signIn.shouldFetchGoogleUserEmail = YES;
    
    signIn.clientID = kClientId;
    
    signIn.scopes = @[kGTLAuthScopePlusLogin];
    
    signIn.delegate = self;
	
}

- (void)refreshInterfaceBasedOnSignIn
{
    if ([[GPPSignIn sharedInstance] authentication])
    {
        printf("User signed in\n");
    }
    else
    {
        printf("User not signed in\n");
    }
}

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error
{
    NSLog(@"Receieved error %@ and auth object %@", error, auth);
    
    if (error)
    {
        // Do some error handling here.
    }
    else
    {
        [self refreshInterfaceBasedOnSignIn];
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
