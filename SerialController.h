//
//  SerialController.h
//  bacttrack
//
//  Created by Bin Liu on 8/23/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PhidgetStepperController.h"
#include "AMSerialPort.h"
#import "PiezoController.h"

extern int stage_x;
extern int stage_y;
extern int stage_z;
extern bool flagstage;
extern float unit_xlen;
extern float unit_zlen;
extern long long actual_x;
extern long long actual_y;
extern long long actual_z;
extern long long actual_z0;
extern int stp_backlash;
extern long long target_x;
extern long long target_y;
extern long long target_z;
extern AMSerialPort *port;
extern NSLock *stage_lock;
extern float target_piezo;
extern float target_piezo_max;
extern float target_piezo_min;
extern int pserial[3];

@interface SerialController : NSObject {
	

	IBOutlet NSTextField *inputTextField;
	IBOutlet NSTextField *deviceTextField;
	IBOutlet NSTextView *outputTextView;
	IBOutlet NSTextField *baudTextField;
	IBOutlet NSTextField *waitTextField;
	IBOutlet NSTimer *trig_control;
    IBOutlet NSTimer *trig_piezoz;
	IBOutlet id m_button_device;
	unsigned int m_BaudRate;
	float m_WaitTime;
	
	IBOutlet id m_control_swith;
	
	IBOutlet NSWindow *window;
	IBOutlet NSTextField *m_speedxy;
	IBOutlet NSTextField *m_speedz;
	IBOutlet NSTextField *m_accelxy;
	IBOutlet NSTextField *m_accelz;
	
	IBOutlet NSTextField *m_posx;
	IBOutlet NSTextField *m_posy;
	IBOutlet NSTextField *m_posz;
	IBOutlet NSTextField *m_scale_text;
    IBOutlet NSTextField *m_serial_x;
    IBOutlet NSTextField *m_serial_y;
    IBOutlet NSTextField *m_serial_z;
	IBOutlet NSSlider *m_scale_tracker;
	IBOutlet NSTextField *m_focus_text;
	IBOutlet NSSlider *m_focus_tracker;
	
	unsigned int speedxy;
	unsigned int speedz;
	unsigned int accelxy;
	unsigned int accelz;
	IBOutlet PhidgetStepperController* m_stepper_1;
	IBOutlet PhidgetStepperController* m_stepper_2;
	IBOutlet PhidgetStepperController* m_stepper_3;
	IBOutlet PiezoController* m_piezoZ;
}

- (AMSerialPort *)port;
- (void)setPort:(AMSerialPort *)newPort;


- (IBAction)listDevices:(id)sender;

- (IBAction)linkDevice:(id)sender;

- (IBAction)chooseDevice:(id)sender;

- (IBAction)dismissDevice:(id)sender;

- (IBAction)send:(id)sender;

- (IBAction)applySetting:(id)sender;

- (IBAction)applySettingOut:(id)sender;


- (IBAction)ControlStage:(id)sender;

- (void) thread_stage;

- (void) trigger_stage;

- (void) update_axis: (int) id_axis;

- (IBAction) setxyRatioBox: (id)sender;

- (IBAction) setxyRatioTracker: (id)sender;

- (IBAction) setzRatioBox: (id)sender;

- (IBAction) setzRatioTracker: (id)sender;

- (void) update_axis:(int)id_axis : (long long *) currpos;

- (void) update_piezoz: (float) pos_z;

- (void) trigger_piezo; 

@end
