//
//  StudySpotsViewController.m
//  StudySpot
//
//  Created by Matthew Werner on 3/3/14.
//  Copyright (c) 2014 Cal Poly. All rights reserved.
//

#import "StudySpotsViewController.h"
#import <WindowsAzureMobileServices/WindowsAzureMobileServices.h>

@interface StudySpotsViewController ()

@property (nonatomic, strong) MSClient *client;
@property (nonatomic, strong) NSMutableArray *enrolledCourses;
@property (nonatomic, strong) NSArray *studySpotList;

@end

@implementation StudySpotsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)studySpotLoadComplete:(NSArray *)studySpots
{
    self.studySpotList = studySpots;
    
    [self.studySpotTable reloadData];
}

- (void)loadStudySpots
{
    MSTable *sSUsrsCrsView = [self.client tableWithName:@"vw_studyspot_courses_users"];
    
    [sSUsrsCrsView readWithCompletion:^(NSArray *items, NSInteger totalCount, NSError *error) {
        if (error)
        {
            NSLog(@"ERROR %@", error);
        }
        else
        {
            [self studySpotLoadComplete:items];
        }

    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize Azure Mobile Service Client
    self.client = [MSClient clientWithApplicationURLString:@"https://studyspot.azure-mobile.net/"
                                            applicationKey:@"UeeXTmfsscRIhhVuCyRqDRwfThBDPa90"];
	
    [self loadStudySpots];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

/* Determines number of rows in table view */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.studySpotList count];
}

/* Populates table view cells with enrolled courses info */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"Futura" size:14.0];
    cell.textLabel.lineBreakMode = NSLineBreakByClipping;
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.text = [NSString stringWithFormat:@"%@\t\t\t%@\n%@ - %@",
                           [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"course"],
                           [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"startdate"],
                           [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"starttime"],
                           [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"endtime"]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Study Spot Info"
                                                    message: [NSString stringWithFormat:@"Creator: %@ %@\nEmail: %@\nCourse: %@\nDate: %@\nTime: %@\nLocation: %@", [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"firstname"], [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"lastname"], [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"email"], [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"course"], [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"startdate"], [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"starttime"], [[self.studySpotList objectAtIndex:indexPath.row] objectForKey:@"location"]]
                                                   delegate: nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
