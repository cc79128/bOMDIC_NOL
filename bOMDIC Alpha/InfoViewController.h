//
//  InfoViewController.h
//  bOMDIC Alpha
//
//  Created by Scott on 2014/7/22.
//  Copyright (c) 2014年 bOMDIC Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfoViewController : UIViewController
@property (strong, nonatomic) IBOutlet UILabel *appVerLabel;
@property (strong, nonatomic) IBOutlet UILabel *fwVerInSensorLabel;
@property (strong, nonatomic) IBOutlet UILabel *manufactureNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *modelNumberLabel;
@property (strong, nonatomic) IBOutlet UILabel *serialNumberLabel;
@property (strong, nonatomic) IBOutlet UILabel *hardwareVerLabel;
@property (strong, nonatomic) IBOutlet UILabel *softwareVerLabel;

@end
