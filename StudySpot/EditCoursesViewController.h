//
//  EditCoursesViewController.h
//  StudySpot
//
//  Created by Matthew Werner on 2/23/14.
//  Copyright (c) 2014 Cal Poly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditCoursesViewController : UIViewController
<UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIPickerView *dept;
@property (weak, nonatomic) IBOutlet UIPickerView *courseNum;
@property (weak, nonatomic) IBOutlet UITableView *coursesTable;
@property (nonatomic, strong) NSString *email;
- (IBAction)addCourseButton:(id)sender;

@end
