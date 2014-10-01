//
//  AppDelegate.h
//  bOMDIC Alpha
//
//  Created by Scott on 2014/7/22.
//  Copyright (c) 2014年 bOMDIC Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WaveViewController.h"
#import "FwUpdateViewController.h"
#import "InfoViewController.h"
#import "LiveMonitorVC.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;
@property (strong, nonatomic) WaveViewController *waveViewController;
@property (strong, nonatomic) FwUpdateViewController *fwUpdateViewController;
@property (strong, nonatomic) InfoViewController *infoViewController;
@property (strong, nonatomic) LiveMonitorVC *liveMonitorVC;

@end
