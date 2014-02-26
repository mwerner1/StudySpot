//
//  LoginViewController.h
//  StudySpot
//
//  Created by Matthew Werner on 2/9/14.
//  Copyright (c) 2014 Cal Poly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GooglePlus/GooglePlus.h>

@class GPPSignInButton;

@interface LoginViewController : UIViewController <GPPSignInDelegate>

- (IBAction)unwindToLogin:(UIStoryboardSegue *)segue;

@end
