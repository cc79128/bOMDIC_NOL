//
//  WaveViewController.m
//  bOMDIC Alpha
//
//  Created by Scott on 2014/7/22.
//  Copyright (c) 2014年 bOMDIC Inc. All rights reserved.
//

#import "WaveViewController.h"
#import "Peripheral.h"

@interface WaveViewController ()

@end

@implementation WaveViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)testAction:(id)sender {
    
    // 連接裝置
    [[Peripheral sharedPeripheral] discoverPheriphral:^(BOOL isConnect) {
        
        if (isConnect) {
            NSLog(@"Connect to Device, HR = %@",[ [Peripheral sharedPeripheral] heartRate]);
        }
        else{
            NSLog(@" Connect to Device Fail!!!!");
        }
        
        
    }];

}
@end
