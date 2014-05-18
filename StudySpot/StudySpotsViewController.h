//
//  StudySpotsViewController.h
//  StudySpot
//
//  Created by Matthew Werner on 3/3/14.
//  Copyright (c) 2014 Cal Poly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StudySpotsViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *studySpotTable;
@property (nonatomic, strong) NSString *email;

- (IBAction)createStudySpots:(id)sender;
- (IBAction)unwindToStudySpots:(UIStoryboardSegue *)segue;
- (IBAction)filterStudySpots:(id)sender;

@end
