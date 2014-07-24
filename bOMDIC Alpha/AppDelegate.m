//
//  AppDelegate.m
//  bOMDIC Alpha
//
//  Created by Scott on 2014/7/22.
//  Copyright (c) 2014年 bOMDIC Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "Peripheral.h"

@implementation AppDelegate
@synthesize window, tabBarController, waveViewController, fwUpdateViewController, infoViewController, liveMonitorVC;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    // instantiate the view controllers:
    self.waveViewController = [[WaveViewController alloc] initWithNibName:nil bundle:nil];
    self.fwUpdateViewController = [[FwUpdateViewController alloc] initWithNibName:nil bundle:nil];
    self.infoViewController = [[InfoViewController alloc] initWithNibName:nil bundle:nil];
    self.liveMonitorVC = [[LiveMonitorVC alloc] initWithNibName:@"LiveMonitor" bundle:nil];
    // a nib name of nil (meaning to use the .xib file we created for each controller), and a bundle of nil (meaning to use this application’s bundle)
    
    
    // set the titles for the view controllers:
    //self.waveViewController.title = @"Wave";
    self.liveMonitorVC.title = @"Wave";
    self.fwUpdateViewController.title = @"Update";
    self.infoViewController.title = @"Info";
    
    // set the images to appear in the tab bar:
    //self.waveViewController.tabBarItem.image = [UIImage imageNamed:@"iconHeart.png"];
    self.liveMonitorVC.tabBarItem.image = [UIImage imageNamed:@"iconHeart.png"];
    self.fwUpdateViewController.tabBarItem.image = [UIImage imageNamed:@"iconFwUpdate.png"];
    self.infoViewController.tabBarItem.image = [UIImage imageNamed:@"iconInfo.png"];
    
    // instantiate the tab bar controller:
    self.tabBarController = [[UITabBarController alloc] init];
    
    // set the tab bar’s view controllers array:
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:
                                             //self.waveViewController,
                                             self.liveMonitorVC,
                                             self.fwUpdateViewController,
                                             self.infoViewController,
                                             nil];
    
    // add the tab bar to the application window as a subview:
    [self.window addSubview:self.tabBarController.view];
    
    // 連接裝置
    [[Peripheral sharedPeripheral] discoverPheriphral:^(BOOL isConnect) {
        
        if (isConnect) {
            NSLog(@"Connect to Device, HR = %@",[ [Peripheral sharedPeripheral] heartRate]);
        }
        else{
            NSLog(@" Connect to Device Fail!!!!");
        }
        
        
    }];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
