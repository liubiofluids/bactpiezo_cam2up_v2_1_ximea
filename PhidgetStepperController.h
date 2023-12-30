/* PhidgetStepperController */

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#include <Phidget22/phidget22.h>

/*extern CPhidgetStepperHandle* m_stepper_x;
extern CPhidgetStepperHandle* m_stepper_y;
extern CPhidgetStepperHandle* m_stepper_z;
*/

#ifndef NPOSBLOCK
#define NPOSBLOCK 20000
#endif

extern int num_phidget_connected;
extern NSLock *phidget_lock;
extern bool flag_stopped;
extern int pserial[3];

@interface PhidgetStepperController : NSObject <NSApplicationDelegate, NSTabViewDelegate, NSWindowDelegate>
{
    IBOutlet id accelerationSetField;
    IBOutlet id accelerationSetTrackBar;
    IBOutlet id connectedField;
    IBOutlet id currentPositionSetTextBox;
    IBOutlet id currentPositionSetTrackBar;
    IBOutlet id currentLabel;
    IBOutlet id currentField;
    IBOutlet id currentTrackBar;
    IBOutlet id enabledCheckBox;
    IBOutlet id inputs;
    IBOutlet id mainWindow;
    IBOutlet id numberOfInputsField;
    IBOutlet id numberOfSteppersField;
    IBOutlet id positionField;
    IBOutlet id positionSetTextBox;
    IBOutlet id positionSetTrackBar;
    IBOutlet id positionTrackBar;
    IBOutlet id serialField;
    IBOutlet id stepperComboBox;
    IBOutlet id stepperComboBoxLabel;
    IBOutlet id stoppedCheckBox;
    IBOutlet id torqueSetLabel;
    IBOutlet id torqueSetField;
    IBOutlet id torqueSetTrackBar;
    IBOutlet id velocityField;
    IBOutlet id velocitySetField;
    IBOutlet id velocitySetTrackBar;
    IBOutlet id velocityTrackBar;
    IBOutlet id versionField;
	IBOutlet NSImageView *pictureBox;
    IBOutlet NSBox *stepperControlBox;
    IBOutlet NSBox *stepperStateBox;
    IBOutlet NSBox *inputsBox;
	IBOutlet NSPanel *passwordPanel;
	IBOutlet NSTextField *passwordField;
    PhidgetStepperHandle stepper;
	int globalIndex;
	unsigned int m_axis;
	IBOutlet int* stepper_pos;
    //Errors
    IBOutlet NSPanel *errorEventLogWindow;
    IBOutlet NSTextView *errorEventLog;
    IBOutlet NSTextField *errorEventLogCounter;
}

- (int) idAxis;
- (long long) getPosition;
- (void)openCmdLine;
- (void)fillForm:(int)index;

/*- (void)openCmdLine;
- (IBAction)clearErrorLog:(id)sender;
- (IBAction)passwordOK:(id)sender;
- (IBAction)passwordCancel:(id)sender;

- (IBAction)setAcceleration:(id)sender;
- (IBAction)setCurrentPosition:(id)sender;
- (IBAction)setCurrentPositionBox:(id)sender;
- (IBAction)setEngaged:(id)sender;
- (IBAction)setPosition:(id)sender;
- (IBAction)setPositionBox:(id)sender;
- (IBAction)setStepper:(id)sender;
- (IBAction)setTorque:(id)sender;
- (IBAction)setVelocity:(id)sender;
- (void)fillForm:(int)index;
- (void)PositionChange:(int)Index index:(long long)posn;
- (void)SpeedChange:(int)Index index:(double)speed;
- (void)CurrentChange:(int)Index index:(double)current;
- (void)InputChange:(int)Index index:(int)State;
- (void)phidgetAdded;
- (void)phidgetRemoved;
- (void)setPicture:(int)version version:(Phidget_DeviceID)devid;

- (void)updatePosition:(int) npos;
- (id) init;
- (long long) getPosition;
 */

@end
