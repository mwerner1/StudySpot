//
//  StudySpotsViewController.h
//  StudySpot
//
//  Created by Matthew Werner on 3/3/14.
//  Copyright (c) 2014 Cal Poly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StudySpotsViewController : UIViewController
<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *studySpotTable;


@end
