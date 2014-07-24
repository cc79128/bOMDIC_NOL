//
//  LiveMonitorVC.h
//  ECG
//
//  Created by Will Yang (yangyu.will@gmail.com) on 4/29/11.
//  Copyright 2013 WMS Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LeadPlayer.h"
#import "Peripheral.h"
#import "NSData+Base64.h"

@interface LiveMonitorVC : UIViewController {

	NSMutableArray *leads, *buffer;
	NSTimer *drawingTimer, *readDataTimer, *recordingTimer, *popDataTimer, *playSoundTimer, *heartRateTimer;
	
	UIImage *recordingImage;
	
	int second;
	BOOL stopTheTimer, autoStart, DEMO, monitoring;
	
	UIButton *btnStart, *btnStop, *photoView;
	
	UIScrollView *scrollView;
	UIImage *screenShot;
	
	int layoutScale;  // 0: 3x4   1: 2x6   2: 1x12
	int startRecordingIndex, endRecordingIndex, HR;
	
	NSString *now;
	BOOL liveMode;
	UILabel *labelRate, *labelProfileId, *labelProfileName, *labelMsg, *labelBat;
	UIBarButtonItem *statusInfo, *btnDismiss, *btnRefresh;
	
	
	int countOfPointsInQueue, countOfRecordingPoints;
	int currentDrawingPoint, bufferCount;
	
	
	LeadPlayer *firstLead;
	
	int lastHR;
    int newBornMode, errorCount;
}

@property (nonatomic, strong) NSMutableArray *leads, *buffer;
@property (nonatomic, strong) IBOutlet UIButton *btnStart, *photoView, *btnRecord;
@property (nonatomic, strong) IBOutlet UIView *vwProfile, *vwMonitor;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic) BOOL liveMode, DEMO;
@property (nonatomic, strong) IBOutlet UILabel *labelProfileId, *labelProfileName, *labelMsg, *labelBat;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *statusInfo, *btnDismiss, *btnRefresh;
@property (nonatomic) int startRecordingIndex, HR, newBornMode;
@property (nonatomic) BOOL stopTheTimer;
- (IBAction)reScanAction:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *connectStatusLabel;
@property (strong, nonatomic) IBOutlet UILabel *labelRate;

@end
