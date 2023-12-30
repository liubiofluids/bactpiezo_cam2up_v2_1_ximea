//
//  PiezoController.h
//  bacttrack
//
//  Created by Bin Liu on 5/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <Phidget22/phidget22.h>
#include <stdio.h>

#import "cvImage.h"

extern float actual_piezo;
extern float target_piezo;
extern bool flagauto;
extern bool flag_focus;
extern NSLock* piezo_lock;
extern NSDate* startdate;

@interface PiezoController : NSObject 
{
	// Task Parameters
	int32_t error;
//	TaskHandle taskHandle;
//	TaskHandle encoHandle;
    
    PhidgetVoltageOutputHandle zout;
    PhidgetVoltageInputHandle zin;
    
	char errBuff[2048];
	// Channel Parameters
	char chan[8];
	char chan_enc[8];
	float vmin;
	float vmax;
	int pointsToRead;
	int pointsRead;
    
	// Timing parameters
	uint samplesPerChan;
	float volt;
    float strain_drift; //drift of strain sensor;
	
	// Control items
    IBOutlet NSWindow *mainWindow;
	IBOutlet id DAQField;
	IBOutlet id DAQScroll;
	IBOutlet id DAQSlide;
	IBOutlet id DAQswitch;
	IBOutlet id Monswitch;
	IBOutlet id VolField;
	IBOutlet id PosField;
	IBOutlet id VdiffField;
	float timeout;
	int pointsWritten;
	NSTimer* trig_monit;
	bool flag_switch;
    size_t sizeBuffer;
    size_t sizeBufferLin;
    float* driftBuffer;
    float* voltBuffer;
    size_t calbSize;
    float calbStep;
    size_t calbTryNum;
    size_t polyOrder;
    float* fitCoeff;
    float* timeBuffer;
    float* exchgStock;
    size_t countBuffer;
    size_t countBufferLin;
    float avgBuffer;
    NSLock* bufferavglock;
    NSLock* voltLock;
    float instanceVolt;
    IBOutlet id buttonCalib;
    bool flag_calib;
}

- (id) init;

- (IBAction) scrollvoltage: (id) sender;

- (IBAction) slidevoltage: (id) sender;

- (IBAction) switchvoltage: (id) sender;

- (IBAction) switchMonitor: (id) sender;

- (IBAction) calibrateVolt: (id) sender;

- (void) updateVolt;

- (void) setVolt: (float) voltvalue;

- (float) getVolt;

- (float) getPanelVolt;

- (void) getDiffVolt;

- (float) getDrift;

- (void) thread_diffVolt;

- (bool) MonitorStatus;

- (void) dealloc;

- (void) polynomialFit: (size_t) size_dat x: (float*) xdata y: (float*) ydata dst: (float*) polyCoeff;

- (void)openCmdLine:(PhidgetHandle)p;
-(void)fillPhidgetInfo:(PhidgetHandle)ch;

@end
