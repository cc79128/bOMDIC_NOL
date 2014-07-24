//
//  LiveMonitorVC.m
//  ECG
//
//  Created by Will Yang (yangyu.will@gmail.com) on 4/29/11.
//  Copyright 2013 WMS Studio. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>
#import "LiveMonitorVC.h"
#import "LeadPlayer.h"
#import "Helper.h"

@implementation LiveMonitorVC
@synthesize leads, btnStart,scrollView, labelProfileId, labelProfileName, btnDismiss;
@synthesize liveMode, labelRate, statusInfo, startRecordingIndex, HR, stopTheTimer;
@synthesize buffer, DEMO, labelMsg, labelBat, photoView, btnRefresh, newBornMode;

int leadCount = 1;
int sampleRate = 500;

float uVpb = 0.9;
float drawingInterval = 0.04;//0.001; // the interval is greater, the drawing is faster, but more choppy, smaller -> slower and smoother
int bufferSecond = 300;
float pixelPerUV = 5 * 10.0 / 1000;

- (void)viewDidLoad {
    [super viewDidLoad];
    labelBat.text = @"";
    labelMsg.text = @"";
    //[self addViews];
    //[self initialMonitor];
    //[self startTimer_getHeartRate]; // add by jeff
    
    /*
    if (![[Peripheral sharedPeripheral] isECGDisplayOpen]) {
        [[Peripheral sharedPeripheral] toggleECGDisplay];
    }
    if (![[Peripheral sharedPeripheral] isECGAnalysisOpen]) {
    [[Peripheral sharedPeripheral] toggleECGAnalysis];
    }
     */
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [self addViews];
    [self initialMonitor];
    [self startTimer_getHeartRate]; // add by jeff
    [self setLeadsLayout:self.interfaceOrientation];
    labelBat.text = @"";
    labelMsg.text = @"";
}

- (void)viewWillDisappear:(BOOL)animated
{
    [drawingTimer invalidate];
    [readDataTimer invalidate];
    [popDataTimer invalidate];
    [heartRateTimer invalidate];
    
    for(UIView *subview in [self.scrollView subviews]) {
        [subview removeFromSuperview];
    }
    [self.leads removeAllObjects];
    
    [super viewWillDisappear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [self startLiveMonitoring];
    // set cmd to device to close ECG wave?
}

-(BOOL)canBecomeFirstResponder 
{
    return YES;
}





#pragma mark -
#pragma mark Initialization, Monitoring and Timer events 

- (void)initialMonitor
{
	bufferCount = 10;
	self.labelMsg.text = @"";
    self.labelBat.text = @"";
    self.btnRecord.enabled = NO;
    self.btnDismiss.enabled = NO;
    
    NSMutableArray *buf = [[NSMutableArray alloc] init];
    self.buffer = buf;
}

- (void)startLiveMonitoring
{
	monitoring = YES;
	stopTheTimer = NO;
    
    [self startTimer_popDataFromBuffer];
    [self startTimer_drawing];
}


-(void)startTimer_getHeartRate{
    
    heartRateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                      target:self
                                                    selector:@selector(readHeartRate)
                                                    userInfo:nil
                                                     repeats:YES];
    
}

- (void)startTimer_popDataFromBuffer
{	
	CGFloat popDataInterval = 1.0f;//420.0f / sampleRate;
	
	popDataTimer = [NSTimer scheduledTimerWithTimeInterval:popDataInterval
													target:self
												  selector:@selector(timerEvent_popData)
												  userInfo:NULL
												   repeats:YES];
}

- (void)startTimer_drawing
{	
	drawingTimer = [NSTimer scheduledTimerWithTimeInterval:drawingInterval
													target:self
												  selector:@selector(timerEvent_drawing)
												  userInfo:NULL
                                                    repeats:YES];
}


- (void)readHeartRate
{
    [labelRate setText:[ [Peripheral sharedPeripheral] heartRate]];

    if ([[ [Peripheral sharedPeripheral] battery_Level] integerValue] <= 0) {
        labelBat.text = @"";
    }
    else {
    labelBat.text = [NSString stringWithFormat:@"BAT:%@%%",[ [Peripheral sharedPeripheral] battery_Level]];
    }

    if ([ [Peripheral sharedPeripheral] signalQuality]){
        [labelMsg setText:@"Good Quality"];
        labelMsg.textColor=[UIColor greenColor];
        labelRate.textColor=[UIColor greenColor];
    }
    else{
        [labelMsg setText:@"Bad Quality"];
        labelMsg.textColor=[UIColor grayColor];
        labelRate.textColor=[UIColor grayColor];
    }
    
    if ([[Peripheral sharedPeripheral] isConnectedToPeriphral]) {
        _connectStatusLabel.text = @"Connected";
        _connectStatusLabel.textColor=[UIColor greenColor];
        labelRate.textColor=[UIColor greenColor];
        labelBat.textColor=[UIColor greenColor];
    }
    else {
        _connectStatusLabel.text = @"Disconnected";
        _connectStatusLabel.textColor=[UIColor grayColor];
        labelRate.textColor=[UIColor grayColor];
        labelBat.textColor=[UIColor grayColor];
        labelMsg.textColor=[UIColor grayColor];
    }
}

- (void)timerEvent_drawing
{
    [self drawRealTime];
}

- (void)timerEvent_popData
{
    if ([[Peripheral sharedPeripheral] isConnectedToPeriphral] && [[Peripheral sharedPeripheral] isCompleteOneSecECG]){
        [self popDemoDataAndPushToLeads];
    }
    else {
        for (LeadPlayer *lead in self.leads)
		{
			[lead.pointsArray removeAllObjects];
            lead.currentPoint = 0;
		}
    }
    
}

- (void)popDemoDataAndPushToLeads
{
	/* original code
     int length = 440;
     short **data = [Helper getDemoData:length];
     
     NSArray *data12Arrays = [self convertDemoData:data dataLength:length doWilsonConvert:NO];
     
     for (int i=0; i<leadCount; i++)
     {
     NSArray *data = [data12Arrays objectAtIndex:i];
     [self pushPoints:data data12Index:i];
     }
     */
    
    
	for (int i=0; i<leadCount; i++)
	{
		
        //jeff
        
        NSString *convertedString = [[NSString alloc] initWithData:[[Peripheral sharedPeripheral] ECGRawData] encoding:NSUTF8StringEncoding];
        NSData *base64Data = [ [NSData alloc] initWithBase64EncodedString:convertedString options:0];
        
        const unsigned char *byte64 = [base64Data bytes];
        
        NSMutableArray *pointsArray = [ [NSMutableArray alloc] init];
        
        int z = [[Peripheral sharedPeripheral] ecgZoom];
        for (int k=0; k<255; k++) {
            //[pointsArray addObject:[NSNumber numberWithUnsignedChar:(((unsigned int)byte64[k]+128*(z-1))/z) ]];
            [pointsArray addObject:[NSNumber numberWithUnsignedInteger:(((unsigned int)byte64[k]+128*(z-1))* 16 /z) ]];

        }//adopt auto zoom back

        NSMutableArray *upSmpPointsArray = [ [NSMutableArray alloc] init];
        int lenghtTuned = 494;//avoid lag plot add by scott
        for (int j=0; j<lenghtTuned; j++) {
            int convertedIIndex = floor(j*255/lenghtTuned);
            [upSmpPointsArray addObject:pointsArray[convertedIIndex]];
        }

        [self pushPoints:upSmpPointsArray data12Index:i];
	}
}

- (void)pushPoints:(NSArray *)_pointsArray data12Index:(NSInteger)data12Index;
{
	LeadPlayer *lead = [self.leads objectAtIndex:data12Index];
    
	if (lead.pointsArray.count > bufferSecond * sampleRate)
	{
		[lead resetBuffer];
	}
	
    if (lead.pointsArray.count - lead.currentPoint <= 2000)
    {
        [lead.pointsArray addObjectsFromArray:_pointsArray];
    }
    
    //Dai_Log(@"Points in Queue:%d",(lead.pointsArray.count - lead.currentPoint));
	
    if (data12Index==0)
	{
		countOfPointsInQueue = lead.pointsArray.count;
		currentDrawingPoint = lead.currentPoint;
	}
}

- (NSArray *)convertDemoData:(short **)rawdata dataLength:(int)length doWilsonConvert:(BOOL)wilsonConvert
{
	NSMutableArray *data = [[NSMutableArray alloc] init];
	for (int i=0; i<12; i++)
	{
		NSMutableArray *array = [[NSMutableArray alloc] init];
		[data addObject:array];
	}
	
    //convert short to NSNumber
	for (int i=0; i<sampleRate; i++)
	{
		for (int j=0; j<12; j++)
		{
			int convertedIIndex = floor(i*255/500);
            NSMutableArray *array = [data objectAtIndex:j];
			NSNumber *number = [NSNumber numberWithInt:rawdata[convertedIIndex][j]];
			[array insertObject:number atIndex:i];
		}
	}//convert short to NSNumber
    
	return data;

}

- (void)drawRealTime
{
	LeadPlayer *l = [self.leads objectAtIndex:0];
	NSInteger zoomChk = [[Peripheral sharedPeripheral] ecgZoom];
    
    
    if (![[Peripheral sharedPeripheral] signalQuality]){
        l.curveColor = @"gray";
    }
    else{
        l.curveColor = @"green";
    }
    
    
    
    
    if (l.pointsArray.count > l.currentPoint &&
        [[Peripheral sharedPeripheral] isConnectedToPeriphral] && [[Peripheral sharedPeripheral] isCompleteOneSecECG])//make sure always play the new data
	{	
		for (LeadPlayer *lead in self.leads)
		{
			[lead fireDrawing];
		}
	}
    else{
        /*
        for (LeadPlayer *lead in self.leads)
		{
			[lead.pointsArray removeAllObjects];
            lead.currentPoint = 0;
		}
        */
        /*
        [self.leads removeAllObjects];
        [self addViews];
        */
        
        [l.pointsArray removeObjectsInRange:NSMakeRange(0, l.pointsArray.count)];
        l.currentPoint = 0;
    }
    
}

- (void)addViews
{	
	NSMutableArray *array = [[NSMutableArray alloc] init];
	
	for (int i=0; i<leadCount; i++) {
		LeadPlayer *lead = [[LeadPlayer alloc] init];
		
        lead.layer.cornerRadius = 8;
        lead.layer.borderColor = [[UIColor grayColor] CGColor];
        lead.layer.borderWidth = 1;
        lead.clipsToBounds = YES;
        
		lead.index = i;
        lead.pointsArray = [[NSMutableArray alloc] init];
                
        lead.liveMonitor = self;
		      
        [array insertObject:lead atIndex:i];
        
        [self.scrollView addSubview:lead];
	}
	
	self.leads = array;
}

- (void)setLeadsLayout:(UIInterfaceOrientation)orientation
{
    float margin = 5;
    NSInteger leadHeight = self.scrollView.frame.size.height;
	NSInteger leadWidth = self.scrollView.frame.size.width;
    scrollView.contentSize = self.scrollView.frame.size;
    
    for (int i=0; i<leadCount; i++)
    {
        LeadPlayer *lead = [self.leads objectAtIndex:i];
        float pos_y = i * (margin + leadHeight);
        
        [lead setFrame:CGRectMake(0., pos_y, leadWidth, leadHeight)];
        lead.pos_x_offset = lead.currentPoint;
        lead.alpha = 0;
        [lead setNeedsDisplay];
    }
    
    [UIView animateWithDuration:0.6f animations:^{
        for (int i=0; i<leadCount; i++)
        {
            LeadPlayer *lead = [self.leads objectAtIndex:i];
            lead.alpha = 1;
        }
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{

}

#pragma mark Memory and others

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)dealloc {
    
    drawingTimer = nil;
	readDataTimer = nil;
	popDataTimer = nil;
	heartRateTimer = nil;
}

- (IBAction)reScanAction:(id)sender {
    
    // disconnect & rescan
    [[Peripheral sharedPeripheral] disconnectFromPheriphral];
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
