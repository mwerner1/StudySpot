//
//  CreateSSViewController.h
//  StudySpot
//
//  Created by Matthew Werner on 4/5/14.
//  Copyright (c) 2014 Cal Poly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreateSSViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>
- (IBAction)saveSSButton:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *addStartTextField;
@property (weak, nonatomic) IBOutlet UITextField *addEndTextField;
@property (weak, nonatomic) IBOutlet UITextField *addCourseTextField;
@property (weak, nonatomic) IBOutlet UITextView *addLocationTextView;
@property (nonatomic, strong) NSString *email;

@end
