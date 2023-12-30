#import "PhidgetStepperxy.h"

extern CPhidgetStepperHandle stepper_x;
extern CPhidgetStepperHandle stepper_y;

int globalIndex_x = 0;

int gotPositionChange(CPhidgetStepperHandle phid, void *context, int ind, long long val) {
	[(id)context PositionChange:ind:val];
	return 0;
}

int gotSpeedChange(CPhidgetStepperHandle phid, void *context, int ind, double val) {
	[(id)context SpeedChange:ind:val];
	return 0;
}

int gotCurrentChange(CPhidgetStepperHandle phid, void *context, int ind, double val) {
	[(id)context CurrentChange:ind:val];
	return 0;
}

int gotInputChange(CPhidgetStepperHandle phid, void *context, int ind, int val) {
	[(id)context InputChange:ind:val];
	return 0;
}

int gotAttach(CPhidgetHandle phid, void *context) {
	[(id)context phidgetAdded];
	return 0;
}

int gotDetach(CPhidgetHandle phid, void *context) {
	[(id)context phidgetRemoved];
	return 0;
}

int gotError(CPhidgetHandle phid, void *context, int errcode, const char *error) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[(id)context performSelectorOnMainThread:@selector(ErrorEvent:)
								  withObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:errcode], [NSString stringWithCString:error], nil]
							   waitUntilDone:NO];
	[pool release];
	return 0;
}

@implementation PhidgetStepperController

- (IBAction)setAcceleration:(id)sender
{
	CPhidgetStepper_setAcceleration(stepper_x, globalIndex_x, [sender doubleValue]);
	[accelerationSetField setStringValue:[NSString stringWithFormat:@"%0.3f", [sender doubleValue]]];
}

- (IBAction)setPosition:(id)sender
{
	CPhidgetStepper_setTargetPosition(stepper_x, globalIndex_x, (long long)[sender intValue]);
	[positionSetTextBox setIntValue:[sender intValue]];
}

- (IBAction)setPositionBox:(id)sender
{
	long long posn;
	const char *posnString = [[sender stringValue] UTF8String];
	posn = strtoll(posnString, NULL, 10);
	CPhidgetStepper_setTargetPosition(stepper_x, globalIndex_x, posn);
}

- (IBAction)setCurrentPosition:(id)sender
{
	CPhidgetStepper_setCurrentPosition(stepper_x, globalIndex_x, (long long)[sender intValue]);
	[currentPositionSetTextBox setIntValue:[sender intValue]];
}

- (IBAction)setEnabled:(id)sender
{
	CPhidgetStepper_setEngaged(stepper_x, globalIndex_x, [sender state]);
}

- (IBAction)setCurrentPositionBox:(id)sender
{
	long long posn;
	const char *posnString = [[sender stringValue] UTF8String];
	posn = strtoll(posnString, NULL, 10);
	CPhidgetStepper_setCurrentPosition(stepper_x, globalIndex_x, posn);
}

- (IBAction)setStepper:(id)sender
{
	const char *stepperString = [[sender stringValue] UTF8String];
	globalIndex_x = strtol(stepperString+8, NULL, 10);
	[self fillForm:globalIndex_x];
}

- (IBAction)setVelocity:(id)sender
{
	CPhidgetStepper_setVelocityLimit(stepper_x, globalIndex_x, [sender doubleValue]);
	[velocitySetField setStringValue:[NSString stringWithFormat:@"%0.3f", [sender doubleValue]]];
}

- (IBAction)setTorque:(id)sender
{
	CPhidgetStepper_setCurrentLimit(stepper_x, globalIndex_x, [sender doubleValue]);
	[torqueSetField setStringValue:[NSString stringWithFormat:@"%0.3f", [sender doubleValue]]];
}

- (void)phidgetAdded
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int serial, version;
	const char *name;
	CPhidget_DeviceID devid;
	int numInputs, numSteppers;
	int i;
	double maxAccel, minAccel, maxVel, minVel;
	int heightChange;
	
	CPhidget_getSerialNumber((CPhidgetHandle)stepper_x, &serial);
	//	int serial2;
	//	CPhidget_getSerialNumber((CPhidgetHandle)stepper_x, &serial2);
	//	NSLog(@"serial: %d", serial2);
	CPhidget_getDeviceVersion((CPhidgetHandle)stepper_x, &version);
	CPhidget_getDeviceName((CPhidgetHandle)stepper_x, &name);
	CPhidget_getDeviceID((CPhidgetHandle)stepper_x, &devid);
	CPhidgetStepper_getInputCount(stepper_x, &numInputs);
	CPhidgetStepper_getMotorCount(stepper_x, &numSteppers);
	
	[connectedField setStringValue:[NSString stringWithCString:name]];
	[serialField setIntValue:serial];
	[versionField setIntValue:version];
	[numberOfInputsField setIntValue:numInputs];
	[numberOfSteppersField setIntValue:numSteppers];
	
	CPhidgetStepper_getAccelerationMax(stepper_x, 0, &maxAccel);
	CPhidgetStepper_getAccelerationMin(stepper_x, 0, &minAccel);
	CPhidgetStepper_getVelocityMax(stepper_x, 0, &maxVel);
	CPhidgetStepper_getVelocityMin(stepper_x, 0, &minVel);
	
	[currentPositionSetTrackBar setMaxValue:20000];
	[currentPositionSetTrackBar setMinValue:-20000];
	[positionTrackBar setMaxValue:20000];
	[positionTrackBar setMinValue:-20000];
	[positionSetTrackBar setMaxValue:20000];
	[positionSetTrackBar setMinValue:-20000];
	[velocityTrackBar setMaxValue:maxVel];
	[velocityTrackBar setMinValue:-maxVel];
	[velocitySetTrackBar setMaxValue:maxVel];
	[velocitySetTrackBar setMinValue:minVel];
	[accelerationSetTrackBar setMaxValue:maxAccel];
	[accelerationSetTrackBar setMinValue:minAccel];
	
	/* Resets to nice initial values - maybe I should not do this? */
	for(i=0;i<numSteppers;i++)
	{
		CPhidgetStepper_setCurrentPosition(stepper_x, i, 0);
		CPhidgetStepper_setAcceleration(stepper_x, i, maxAccel/2.0);
		CPhidgetStepper_setVelocityLimit(stepper_x, i, maxVel/2.0);
	}
	
	NSRect frame = [mainWindow frame];
	
	switch(devid)
	{
		case PHIDID_BIPOLAR_STEPPER_1MOTOR:
		{
			double maxCurrent, minCurrent;
			CPhidgetStepper_getCurrentMax(stepper_x, 0, &maxCurrent);
			CPhidgetStepper_getCurrentMin(stepper_x, 0, &minCurrent);
			[currentTrackBar setMaxValue:maxCurrent];
			[currentTrackBar setMinValue:minCurrent];
			[torqueSetTrackBar setMaxValue:maxCurrent];
			[torqueSetTrackBar setMinValue:minCurrent];
		}
			heightChange = frame.size.height - 562;
			[inputsBox setHidden:FALSE];
			[inputsBox setHidden:FALSE];
			[torqueSetTrackBar setHidden:FALSE];
			[currentTrackBar setHidden:FALSE];
			[currentField setHidden:FALSE];
			[torqueSetField setHidden:FALSE];
			[currentLabel setHidden:FALSE];
			[torqueSetLabel setHidden:FALSE];
			[stepperComboBox setHidden:TRUE];
			[stepperComboBoxLabel setHidden:TRUE];
			break;
		case PHIDID_UNIPOLAR_STEPPER_4MOTOR:
			heightChange = frame.size.height - 505;
			[inputsBox setHidden:TRUE];
			[torqueSetTrackBar setHidden:TRUE];
			[currentTrackBar setHidden:TRUE];
			[currentField setHidden:TRUE];
			[torqueSetField setHidden:TRUE];
			[currentLabel setHidden:TRUE];
			[torqueSetLabel setHidden:TRUE];
			[stepperComboBox setHidden:FALSE];
			[stepperComboBoxLabel setHidden:FALSE];
			break;
		default:
			break;
	}
	
	[self fillForm:0];
	
	[stepperStateBox setHidden:FALSE];
	[stepperControlBox setHidden:FALSE];
	
	frame.origin.y += heightChange;
	frame.size.height -= heightChange;
	[mainWindow setMinSize:frame.size];
	[mainWindow setFrame:frame display:YES animate:NO];
	
	[self setPicture:version:devid];
	[pool release];
	[mainWindow display];
}

- (void)fillForm:(int)index
{
	long long posn, targetPosn;
	double velocity, velocityLimit;
	double accel, current, currentLimit;
	int stopped, engaged;
	
	CPhidgetStepper_getVelocity(stepper_x, index, &velocity);
	CPhidgetStepper_getAcceleration(stepper_x, index, &accel);
	CPhidgetStepper_getVelocityLimit(stepper_x, index, &velocityLimit);
	CPhidgetStepper_getCurrentPosition(stepper_x, index, &posn);
	CPhidgetStepper_getTargetPosition(stepper_x, index, &targetPosn);
	CPhidgetStepper_getEngaged(stepper_x, index, &engaged);
	CPhidgetStepper_getStopped(stepper_x, index, &stopped);
	
	if(!CPhidgetStepper_getCurrent(stepper_x, index, &current))
	{
		[currentField setStringValue:[NSString stringWithFormat:@"%0.3f", current]];
		[currentTrackBar setDoubleValue:current];
	}
	if(!CPhidgetStepper_getCurrentLimit(stepper_x, index, &currentLimit))
	{
		[torqueSetField setStringValue:[NSString stringWithFormat:@"%0.3f", currentLimit]];
		[torqueSetTrackBar setDoubleValue:currentLimit];
	}
	
	[velocitySetField setStringValue:[NSString stringWithFormat:@"%0.3f", velocityLimit]];
	[velocitySetTrackBar setDoubleValue:velocityLimit];
	[accelerationSetField setStringValue:[NSString stringWithFormat:@"%0.3f", accel]];
	[accelerationSetTrackBar setDoubleValue:accel];
	[positionSetTextBox setIntValue:targetPosn];
	[positionSetTrackBar setIntValue:targetPosn];
	
	[positionField setIntValue:posn];
	[positionTrackBar setIntValue:posn];
	[velocityField setStringValue:[NSString stringWithFormat:@"%0.3f", velocity]];
	[velocityTrackBar setDoubleValue:velocity];
	
	[stoppedCheckBox setState:stopped];
	[enabledCheckBox setState:engaged];
}

- (void)phidgetRemoved
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[connectedField setTitleWithMnemonic:@"Nothing"];
	[serialField setTitleWithMnemonic:@""];
	[versionField setTitleWithMnemonic:@""];
	[numberOfInputsField setTitleWithMnemonic:@""];
	[numberOfSteppersField setTitleWithMnemonic:@""];
	
	[inputsBox setHidden:TRUE];
	[stepperStateBox setHidden:TRUE];
	[stepperControlBox setHidden:TRUE];
	
	NSRect frame = [mainWindow frame];
	int heightChange = frame.size.height - 195;
	frame.origin.y += heightChange;
	frame.size.height -= heightChange;
	[mainWindow setMinSize:frame.size];
	[mainWindow setFrame:frame display:YES animate:NO];
	
	[self setPicture:0:0];
	
	[pool release];
	[mainWindow display];
}

- (void)PositionChange:(int)Index:(long long)posn
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int stopped;
	if(globalIndex_x == Index) {
		[positionField setIntValue:(int)posn];
		[positionTrackBar setIntValue:(int)posn];
		CPhidgetStepper_getStopped(stepper_x, Index, &stopped);
		[stoppedCheckBox setState:stopped];
	}
	[pool release];
}

- (void)SpeedChange:(int)Index:(double)speed
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int stopped;
	if(globalIndex_x == Index) {
		[velocityField setStringValue:[NSString stringWithFormat:@"%0.3f", speed]];
		[velocityTrackBar setDoubleValue:speed];
		CPhidgetStepper_getStopped(stepper_x, Index, &stopped);
		[stoppedCheckBox setState:stopped];
	}
	[pool release];
}

- (void)CurrentChange:(int)Index:(double)current
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if(globalIndex_x == Index) {
		[currentField setStringValue:[NSString stringWithFormat:@"%0.3f", current]];
		[currentTrackBar setDoubleValue:current];
	}
	[pool release];
}

- (void)InputChange:(int)Index:(int)State
{
	[[inputs cellWithTag:Index] setState:State];
}

- (void)openCmdLine
{
	int serial = -1, remote = 0;
	NSArray *args = [[NSProcessInfo processInfo] arguments];
	if([args count] > 1)
	{
		if([[args objectAtIndex:1] isEqualToString:@"remote"])
			remote = 1;
		serial = [[args objectAtIndex:[args count]-1] intValue];
		if(serial == 0) serial = -1;
	}
	
	if(remote)
		CPhidget_openRemote((CPhidgetHandle)stepper_x, serial, NULL, [[passwordField stringValue] UTF8String]);
	else
		CPhidget_open((CPhidgetHandle)stepper_x, serial);
}

/*
 * This gets run when the GUI gets displayed
 */
- (void)awakeFromNib
{
	int serial = -1, remote = 0;
	NSArray *args = [[NSProcessInfo processInfo] arguments];
	if([args count] > 1)
	{
		if([[args objectAtIndex:1] isEqualToString:@"remote"])
			remote = 1;
		serial = strtol([[args objectAtIndex:[args count]-1] UTF8String], NULL, 10);
		if(serial == 0) serial = -1;
	}
	
	[mainWindow setDelegate:self];
	
	CPhidgetStepper_create(&stepper_x);
	
	CPhidget_set_OnAttach_Handler((CPhidgetHandle)stepper_x, gotAttach, self);
	CPhidget_set_OnDetach_Handler((CPhidgetHandle)stepper_x, gotDetach, self);
	CPhidgetStepper_set_OnPositionChange_Handler(stepper_x, gotPositionChange, self);
	CPhidgetStepper_set_OnVelocityChange_Handler(stepper_x, gotSpeedChange, self);
	CPhidgetStepper_set_OnCurrentChange_Handler(stepper_x, gotCurrentChange, self);
	CPhidgetStepper_set_OnInputChange_Handler(stepper_x, gotInputChange, self);
	CPhidget_set_OnError_Handler((CPhidgetHandle)stepper_x, gotError, self);
	
	[self openCmdLine];
}

- (void)windowWillClose:(NSNotification *)aNotification {
	CPhidget_close((CPhidgetHandle)stepper_x);
	CPhidget_delete((CPhidgetHandle)stepper_x);
	stepper_x = NULL;
	[NSApp terminate:self];
}

- (void)setPicture:(int)version:(CPhidget_DeviceID)devid
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *imgPath;
	
	switch(devid)
	{
		case PHIDID_BIPOLAR_STEPPER_1MOTOR:
			imgPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"1063_0" ofType:@"icns"];
			break;
		case PHIDID_UNIPOLAR_STEPPER_4MOTOR:
			imgPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"1062_0" ofType:@"icns"];
			break;
		default:
			imgPath = nil;
			break;
	}
	
	NSImage *img = [[NSImage alloc]  initByReferencingFile:imgPath];
	
	//otherwise the images are just painted over each other - and the transparency causes trouble
	[pictureBox setImage:nil];
	[pictureBox display];
	if(imgPath!=nil)
		[NSApp setApplicationIconImage: img];
	[pictureBox setImage:img];
	[pictureBox display];
	
	[pool release];
}

int errorCounter = 0;
- (void)ErrorEvent:(NSArray *)errorEventData
{
	int errorCode = [[errorEventData objectAtIndex:0] intValue];
	NSString *errorString = [errorEventData objectAtIndex:1];
	
	switch(errorCode)
	{
		case EEPHIDGET_BADPASSWORD:
			CPhidget_close((CPhidgetHandle)stepper_x);
			[NSApp runModalForWindow:passwordPanel];
			break;
		case EEPHIDGET_BADVERSION:
			CPhidget_close((CPhidgetHandle)stepper_x);
			NSRunAlertPanel(@"Version mismatch", [NSString stringWithFormat:@"%@\nApplication will now close.", errorString], nil, nil, nil);
			[NSApp terminate:self];
			break;
		default:
			errorCounter++;
			
			NSAttributedString *string = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",errorString]];
			
			[[errorEventLog textStorage] beginEditing];
			[[errorEventLog textStorage] appendAttributedString:string];
			[[errorEventLog textStorage] endEditing];
			
			[errorEventLogCounter setIntValue:errorCounter];
			if(![errorEventLogWindow isVisible])
				[errorEventLogWindow setIsVisible:YES];
			break;
	}
}

- (IBAction)clearErrorLog:(id)sender
{
	[[errorEventLog textStorage] setAttributedString:[[NSAttributedString alloc] initWithString:@""]];
	[errorEventLogCounter setIntValue:0];
	errorCounter = 0;
}

- (IBAction)passwordOK:(id)sender
{
	[passwordPanel setIsVisible:NO];
	[NSApp stopModal];
	[self openCmdLine];
	[passwordField setStringValue:@""];
}

- (IBAction)passwordCancel:(id)sender
{
	[passwordPanel setIsVisible:NO];
	[NSApp stopModal];
	[NSApp terminate:self];
}
@end

