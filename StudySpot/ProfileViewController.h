//
//  ProfileViewController.h
//  StudySpot
//
//  Created by Matthew Werner on 2/9/14.
//  Copyright (c) 2014 Cal Poly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WindowsAzureMobileServices/WindowsAzureMobileServices.h>

@interface ProfileViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *firstNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *schoolLabel;
@property (nonatomic, strong) NSString *email;
- (IBAction)editCourses:(id)sender;

@end
