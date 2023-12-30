/* PhidgetStepperController */

#import <Cocoa/Cocoa.h>
#include <Phidget21/phidget21.h>

@interface PhidgetStepperController : NSObject
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
	
	IBOutlet NSPanel *errorEventLogWindow;
	IBOutlet NSTextView *errorEventLog;
	IBOutlet NSTextField *errorEventLogCounter;
	IBOutlet NSPanel *passwordPanel;
	IBOutlet NSTextField *passwordField;
}
- (void)openCmdLine;

- (IBAction)clearErrorLog:(id)sender;
- (IBAction)passwordOK:(id)sender;
- (IBAction)passwordCancel:(id)sender;

- (IBAction)setAcceleration:(id)sender;
- (IBAction)setCurrentPosition:(id)sender;
- (IBAction)setCurrentPositionBox:(id)sender;
- (IBAction)setEnabled:(id)sender;
- (IBAction)setPosition:(id)sender;
- (IBAction)setPositionBox:(id)sender;
- (IBAction)setStepper:(id)sender;
- (IBAction)setTorque:(id)sender;
- (IBAction)setVelocity:(id)sender;
- (void)fillForm:(int)index;
- (void)PositionChange:(int)Index:(long long)posn;
- (void)SpeedChange:(int)Index:(double)speed;
- (void)CurrentChange:(int)Index:(double)current;
- (void)InputChange:(int)Index:(int)State;
- (void)phidgetAdded;
- (void)phidgetRemoved;
- (void)setPicture:(int)version:(CPhidget_DeviceID)devid;
@end
