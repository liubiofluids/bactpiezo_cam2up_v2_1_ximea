#import "PhidgetStepperController.h"



int gotPositionChange(PhidgetStepperHandle phid, void *context, int ind, long long val) {
	[(id)context PositionChange:ind:val];
	return 0;
}

int gotSpeedChange(PhidgetStepperHandle phid, void *context, int ind, double val) {
	[(id)context SpeedChange:ind:val];
	return 0;
}

int gotCurrentChange(PhidgetStepperHandle phid, void *context, int ind, double val) {
	[(id)context CurrentChange:ind:val];
	return 0;
}

int gotInputChange(PhidgetStepperHandle phid, void *context, int ind, int val) {
	[(id)context InputChange:ind:val];
	return 0;
}

/*
#pragma mark Event callbacks
static void gotAttach(PhidgetHandle phid, void *context){
    [(__bridge id)context performSelectorOnMainThread:@selector(onAttachHandler)
                                           withObject:nil
                                        waitUntilDone:NO];
}
static void gotDetach(PhidgetHandle phid, void *context){
    [(__bridge id)context performSelectorOnMainThread:@selector(onDetachHandler)
                                           withObject:nil
                                        waitUntilDone:NO];
}
static void gotError(PhidgetHandle phid, void *context, Phidget_ErrorEventCode errcode, const char *error){
    [(__bridge id)context performSelectorOnMainThread:@selector(errorHandler:)
                                           withObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:errcode], [NSString stringWithUTF8String:error], nil]
                                        waitUntilDone:NO];
}
static void gotPositionChangeData(PhidgetStepperHandle phid, void *context, double position){
        [(__bridge id)context performSelectorOnMainThread:@selector(onPositionChangeHandler:)
                                               withObject:[NSNumber numberWithDouble:position]
                                            waitUntilDone:NO];
}
static void gotStoppedData(PhidgetStepperHandle phid, void *context){
        [(__bridge id)context performSelectorOnMainThread:@selector(onStoppedHandler)
                                               withObject:nil
                                            waitUntilDone:NO];
}
static void gotVelocityChangeData(PhidgetStepperHandle phid, void *context, double velocity){
        [(__bridge id)context performSelectorOnMainThread:@selector(onVelocityChangeHandler:)
                                               withObject:[NSNumber numberWithDouble:velocity]
                                            waitUntilDone:NO];
}
 */

@implementation PhidgetStepperController
static NSMutableArray *listSerial;


- (void)windowWillClose:(NSNotification*)aNotification{
    if(stepper){
        //Safely close example
        Phidget_setOnAttachHandler((PhidgetHandle)stepper, NULL, NULL);
        Phidget_setOnDetachHandler((PhidgetHandle)stepper, NULL, NULL);
        Phidget_setOnErrorHandler((PhidgetHandle)stepper, NULL, NULL);
        Phidget_close((PhidgetHandle)stepper);
        PhidgetStepper_delete(&stepper);
        m_axis = NULL;
    }
}

-(void)awakeFromNib{
    
    /*
     NSLog(@"phidget awake 0");
     int serial = -1, remote = 0;
     NSArray *args=[[NSProcessInfo processInfo] arguments];
     if([args count] > 1)
     {
         if([[args objectAtIndex:1] isEqualToString:@"remote"])
             remote = 1;
         serial = strtol([[args objectAtIndex:[args count]-1] UTF8String], NULL, 10);
         if(serial == 0) serial = -1;
     }

     
     [mainWindow setDelegate:self];
     CPhidgetStepper_create(&stepper); //causing freezing while the controller is connected during start up
     
     CPhidget_set_OnAttach_Handler((CPhidgetHandle)stepper, gotAttach, self);
     CPhidget_set_OnDetach_Handler((CPhidgetHandle)stepper, gotDetach, self);
     CPhidgetStepper_set_OnPositionChange_Handler(stepper, gotPositionChange, self);
     CPhidgetStepper_set_OnVelocityChange_Handler(stepper, gotSpeedChange, self);
     CPhidgetStepper_set_OnCurrentChange_Handler(stepper, gotCurrentChange, self);
     CPhidgetStepper_set_OnInputChange_Handler(stepper, gotInputChange, self);
     CPhidget_set_OnError_Handler((CPhidgetHandle)stepper, gotError, self);
     [self openCmdLine];
     */
    
    PhidgetReturnCode result;
    double minheight = 195.;
    NSLog(@"phidget awake 0");
    int serial = -1, remote = 0;
    NSArray *args=[[NSProcessInfo processInfo] arguments];
    if([args count] > 1)
    {
        if([[args objectAtIndex:1] isEqualToString:@"remote"])
            remote = 1;
        serial = strtol([[args objectAtIndex:[args count]-1] UTF8String], NULL, 10);
        if(serial == 0) serial = -1;
    }
    
    //Manage GUI
    NSRect frame = [mainWindow frame];
//    frame.size.height = [mainWindow minSize].height;
    frame.size.height = minheight;
    [mainWindow setFrame:frame display:NO];
    [mainWindow center];
    [mainWindow setDelegate:self];
//    [phidgetInfoBoxView fillPhidgetInfo:nil];
//    [phidgetInfoBox setHidden:NO];
    
    result = PhidgetStepper_create(&stepper);
    if(result != EPHIDGET_OK){
        [self outputLastError];
    }
    
    result = [self initChannel:(PhidgetHandle)stepper];
    if(result != EPHIDGET_OK){
        [self outputLastError];
    }
 
    result = PhidgetStepper_setOnStoppedHandler(stepper, gotStoppedData, (__bridge void*)self);
    if(result != EPHIDGET_OK){
        [self outputLastError];
    }
    
    result = PhidgetStepper_setOnPositionChangeHandler(stepper, gotPositionChangeData, (__bridge void*)self);
    if(result != EPHIDGET_OK){
        [self outputLastError];
    }
    
    result = PhidgetStepper_setOnVelocityChangeHandler(stepper, gotVelocityChangeData, (__bridge void*)self);
    if(result != EPHIDGET_OK){
        [self outputLastError];
    }
    [self openCmdLine];
    
//    [PhidgetInfoBox openCmdLine:(PhidgetHandle)stepper];
//    [tabBox setDelegate:self];
}


- (id)init {
	globalIndex=0;
//	NSLog(@"phidget_lock: %d", phidget_lock);
	if(!phidget_lock){
		phidget_lock=[[NSLock alloc] init];
//		NSLog(@"phidget_lock: %d", phidget_lock);
	}
	
//	[phidget_lock lock];
	if (self = [super init]) {
		
	}
//	[phidget_lock unlock];
	return self;
}

-(PhidgetReturnCode)initChannel:(PhidgetHandle) channel{
    PhidgetReturnCode result;
    
    result = Phidget_setOnAttachHandler(channel, gotAttach, (__bridge void*)self);
    if(result != EPHIDGET_OK){
        return result;
    }

    result = Phidget_setOnDetachHandler(channel, gotDetach, (__bridge void*)self);
    if(result != EPHIDGET_OK){
        return result;
    }
    
    result = Phidget_setOnErrorHandler(channel, gotError, (__bridge void*)self);
    if(result != EPHIDGET_OK){
        return result;
    }
    
    /*
     * Please review the Phidget22 channel matching documentation for details on the device
     * and class architecture of Phidget22, and how channels are matched to device features.
     */
    
    /*
     * Specifies the serial number of the device to attach to.
     * For VINT devices, this is the hub serial number.
     *
     * The default is any device.
     */
    // Phidget_setDeviceSerialNumber(ch, <YOUR DEVICE SERIAL NUMBER>);
    
    /*
     * For VINT devices, this specifies the port the VINT device must be plugged into.
     *
     * The default is any port.
     */
    // Phidget_setHubPort(ch, 0);
    
    /*
     * Specifies that the channel should only match a VINT hub port.
     * The only valid channel id is 0.
     *
     * The default is 0 (false), meaning VINT hub ports will never match
     */
    // Phidget_setIsHubPortDevice(ch, 1);
    
    /*
     * Specifies which channel to attach to.  It is important that the channel of
     * the device is the same class as the channel that is being opened.
     *
     * The default is any channel.
     */
    // Phidget_setChannel(ch, 0);
    
    /*
     * In order to attach to a network Phidget, the program must connect to a Phidget22 Network Server.
     * In a normal environment this can be done automatically by enabling server discovery, which
     * will cause the client to discovery and connect to available servers.
     *
     * To force the channel to only match a network Phidget, set remote to 1.
     */
    // PhidgetNet_enableServerDiscovery(PHIDGETSERVER_DEVICEREMOTE);
    // Phidget_setIsRemote(ch, 1);
    
    return EPHIDGET_OK;
}

#pragma mark Event callbacks
static void gotAttach(PhidgetHandle phid, void *context){
    [(__bridge id)context performSelectorOnMainThread:@selector(onAttachHandler)
                                           withObject:nil
                                        waitUntilDone:NO];
}
static void gotDetach(PhidgetHandle phid, void *context){
    [(__bridge id)context performSelectorOnMainThread:@selector(onDetachHandler)
                                           withObject:nil
                                        waitUntilDone:NO];
}
static void gotError(PhidgetHandle phid, void *context, Phidget_ErrorEventCode errcode, const char *error){
    [(__bridge id)context performSelectorOnMainThread:@selector(errorHandler:)
                                           withObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:errcode], [NSString stringWithUTF8String:error], nil]
                                        waitUntilDone:NO];
}
static void gotPositionChangeData(PhidgetStepperHandle phid, void *context, double position){
        [(__bridge id)context performSelectorOnMainThread:@selector(onPositionChangeHandler:)
                                               withObject:[NSNumber numberWithDouble:position]
                                            waitUntilDone:NO];
}
static void gotStoppedData(PhidgetStepperHandle phid, void *context){
        [(__bridge id)context performSelectorOnMainThread:@selector(onStoppedHandler)
                                               withObject:nil
                                            waitUntilDone:NO];
}
static void gotVelocityChangeData(PhidgetStepperHandle phid, void *context, double velocity){
        [(__bridge id)context performSelectorOnMainThread:@selector(onVelocityChangeHandler:)
                                               withObject:[NSNumber numberWithDouble:velocity]
                                            waitUntilDone:NO];
}

#pragma mark Attach, detach, data, and error events
- (void)onAttachHandler{
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int serial, version;
    const char *name;
    Phidget_DeviceID devid;
    int numInputs, numSteppers;
    int i;
    double maxAccel, minAccel, maxVel, minVel;
    double minCurrentLimit, maxCurrentLimit, currentLimit;

    PhidgetReturnCode result;
    int heightChange = 312;
    
    double minheight = 195.;
    int engaged;
    
    //Get information from channel that will allow us to configure the GUI properly
    result = Phidget_getDeviceID((PhidgetHandle)stepper, &devid);
    
    NSLog(@"device id: %d", devid);
    if(result != EPHIDGET_OK){
        [self outputLastError];
    }
    result = PhidgetStepper_getMaxCurrentLimit(stepper, &maxCurrentLimit);
    if(result != EPHIDGET_OK){
        [self outputLastError];
    }
    result = PhidgetStepper_getMinCurrentLimit(stepper, &minCurrentLimit);
    if(result != EPHIDGET_OK){
        [self outputLastError];
    }
    result = PhidgetStepper_getCurrentLimit(stepper, &currentLimit);
    if(result != EPHIDGET_OK){
        [self outputLastError];
    }
    result = PhidgetStepper_getEngaged(stepper, &engaged);
    if(result != EPHIDGET_OK){
        [self outputLastError];
    }

    //Adjust GUI based on information from channel
//    [phidgetInfoBoxView fillPhidgetInfo:(PhidgetHandle)stepper];

    [stepperStateBox setHidden:FALSE]; //    [motorStatusBox setHidden:NO];
    [stepperControlBox setHidden:FALSE]; //    [tabBox setHidden:NO];

    Phidget_getDeviceSerialNumber((PhidgetHandle)stepper, &serial);
    //Phidget_getSerialNumber((CPhidgetHandle)stepper, &serial);
    Phidget_getDeviceName((PhidgetHandle)stepper, &name);
    Phidget_getDeviceVersion((PhidgetHandle)stepper, &version);

    numInputs=0;
    numSteppers=0;
    
    NSLog(@"serial: %d", serial);
    
    
    if (serial == pserial[2]) {
            m_axis=3;
//            m_stepper_z=&stepper;
            [mainWindow setTitle: @"Stepper Z"];
    }
    else if (serial == pserial[0]){
            m_axis=1;
//            m_stepper_x=&stepper;
            [mainWindow setTitle: @"Stepper X"];
    }
    else if (serial == pserial[1]){
            m_axis=2;
//            m_stepper_x=&stepper;
            [mainWindow setTitle: @"Stepper Y"];
    }
    else {
            if (serial>0){
                NSLog(@"sn: %d, did: %d, %d", serial, PHIDID_1067, devid);
                m_axis=4;
                [mainWindow setTitle: @"Pump "];
            }
    }
    NSRect winFrame = [mainWindow frame];

    NSLog(@"device name: %s", name);
    [connectedField setStringValue:[NSString stringWithUTF8String:name]];
    [serialField setIntValue:serial];
    [versionField setIntValue:version];
    [numberOfInputsField setIntValue:numInputs];
    [numberOfSteppersField setIntValue:numSteppers];
    
    if(m_axis==1 || m_axis==2){
        maxVel=1800;
        minVel=250;
    }
    else if (m_axis==3){
        maxVel=3600;
        minVel=250;
    }
    else if (m_axis==4){
        maxVel=3600;
        minVel=20;
    }
    
    [currentTrackBar setHidden:FALSE];
    [currentTrackBar setMaxValue:maxCurrentLimit];
    [currentTrackBar setMinValue:minCurrentLimit];
    [currentLabel setStringValue:@"0.00 A"];
    [velocityTrackBar setMinValue: minVel];
    [velocityTrackBar setMaxValue: maxVel];
    [velocitySetTrackBar setMaxValue:maxVel];
    [velocitySetTrackBar setMinValue:minVel];
    [accelerationSetTrackBar setMaxValue:maxAccel];
    [accelerationSetTrackBar setMinValue:minAccel];

    //Adjusting view height

    [self fillForm:0];
    
    [stepperStateBox setHidden:FALSE];
    [stepperControlBox setHidden:FALSE];
//    [phidget_lock unlock];
    NSLog(@"winsize: %f", winFrame.size.height);
    if(winFrame.size.height == minheight){
        winFrame.origin.y += heightChange;
        winFrame.size.height += heightChange;
    }
    NSLog(@"winsize: %f", winFrame.size.height);

//    NSLog(@"add: 3");
//    [phidget_lock lock];
    [mainWindow setMinSize:winFrame.size];
    [mainWindow setFrame:winFrame display:YES animate:NO];
//    [phidget_lock unlock];
    [self setPicture:version:devid];
    [pool release];
//    NSLog(@"add: 4");

    [mainWindow display];

//    [phidget_lock lock];
//    NSLog(@"add: 4~");
//    num_phidget_connected++;
    NSLog(@"Added done!");
//    [phidget_lock unlock];

}

- (IBAction)setAcceleration:(id)sender
{
    PhidgetStepper_setAcceleration(stepper, [sender doubleValue]);
//	PhidgetStepper_setAcceleration(stepper, globalIndex, [sender doubleValue]);
 	[accelerationSetField setStringValue:[NSString stringWithFormat:@"%0.3f", [sender doubleValue]]];
}

- (IBAction)setPosition:(id)sender
{
    PhidgetStepper_setTargetPosition(stepper, (long long)[sender intValue]);
//	PhidgetStepper_setTargetPosition(stepper, globalIndex, (long long)[sender intValue]);
	[positionSetTextBox setIntValue:[sender intValue]];
}

- (IBAction)setPositionBox:(id)sender
{
	long long posn;
	const char *posnString = [[sender stringValue] UTF8String];
	posn = strtoll(posnString, NULL, 10);
    PhidgetStepper_setTargetPosition(stepper, posn);
//	PhidgetStepper_setTargetPosition(stepper, globalIndex, posn);
}

- (IBAction)setCurrentPosition:(id)sender
{
//	PhidgetStepper_setCurrentPosition(stepper, globalIndex, (long long)[sender intValue]);
	[currentPositionSetTextBox setIntValue:[sender intValue]];
    [currentPositionSetTrackBar setIntValue:[sender intValue]];
}

- (IBAction)setEngaged:(id)sender
{
    PhidgetStepper_setEngaged(stepper, [sender state]);
//	PhidgetStepper_setEngaged(stepper, globalIndex, [sender state]);
}

- (IBAction)setCurrentPositionBox:(id)sender
{
	long long posn;
	const char *posnString = [[sender stringValue] UTF8String];
	posn = strtoll(posnString, NULL, 10);
    PhidgetStepper_setTargetPosition(stepper, posn);
//	PhidgetStepper_setCurrentPosition(stepper, globalIndex, posn);
}

- (IBAction)setStepper:(id)sender
{
	const char *stepperString = [[sender stringValue] UTF8String];
	globalIndex = strtol(stepperString+8, NULL, 10);
	[self fillForm:globalIndex];
}

- (IBAction)setVelocity:(id)sender
{
    PhidgetStepper_setVelocityLimit(stepper, [sender doubleValue]);
	//PhidgetStepper_setVelocityLimit(stepper, globalIndex, [sender doubleValue]);
	[velocitySetField setStringValue:[NSString stringWithFormat:@"%0.3f", [sender doubleValue]]];
    [velocitySetTrackBar setValue: [sender doubleValue]];
}

- (IBAction)setTorque:(id)sender
{
    PhidgetStepper_setCurrentLimit(stepper, [sender doubleValue]);
	//PhidgetStepper_setCurrentLimit(stepper, globalIndex, [sender doubleValue]);
	[torqueSetField setStringValue:[NSString stringWithFormat:@"%0.3f", [sender doubleValue]]];
    [torqueSetTrackBar setValue: [sender doubleValue]];
}

- (void)fillForm:(int)index
{
	long long posn, targetPosn;
	double velocity, velocityLimit;
	double accel, current, currentLimit;
	int stopped, engaged;
	
    PhidgetStepper_getVelocity(stepper, &velocity);
	//CPhidgetStepper_getVelocity(stepper, index, &velocity);
    PhidgetStepper_getAcceleration(stepper, &accel);
	//CPhidgetStepper_getAcceleration(stepper, index, &accel);
    PhidgetStepper_getVelocity(stepper, &velocityLimit);
    //CPhidgetStepper_getVelocityLimit(stepper, index, &velocityLimit);
    PhidgetStepper_getPosition(stepper, &posn);
    //CPhidgetStepper_getCurrentPosition(stepper, index, &posn);
    PhidgetStepper_getTargetPosition(stepper, &targetPosn);
    //CPhidgetStepper_getTargetPosition(stepper, index, &targetPosn);
    PhidgetStepper_getEngaged(stepper, &engaged);
    //CPhidgetStepper_getEngaged(stepper, index, &engaged);
    PhidgetStepper_setEngaged(stepper, 0);
    //CPhidgetStepper_setEngaged(stepper, index, 0);
	engaged=0;
    
	//CPhidgetStepper_getStopped(stepper, index, &stopped);
	
/*	if(!PhidgetStepper_getCurrent(stepper, &current))
	{
		[currentField setStringValue:[NSString stringWithFormat:@"%0.3f", current]];
		[currentTrackBar setDoubleValue:current];
	}
 */
	if(!PhidgetStepper_getCurrentLimit(stepper, &currentLimit))
	{
		//currentLimit=0.1; //for safety to avoid overheating of test motor
		[torqueSetField setStringValue:[NSString stringWithFormat:@"%0.3f", currentLimit]];
		[torqueSetTrackBar setDoubleValue:currentLimit];
	}
    velocityLimit=500.0;
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

- (void)onDetachHandler{
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
    int posmax, posmin;
	if(globalIndex == Index) {
        posmax=[positionTrackBar maxValue];
        posmin=[positionTrackBar minValue];
        if (posn>=posmax) {
            posmax=posmax+NPOSBLOCK;
        }
            else if (posn<posmin){
            posmin=posmin-NPOSBLOCK;
        }
        [positionTrackBar setIntValue:posmax];
		[positionField setIntValue:(int)posn];
		[positionTrackBar setIntValue:(int)posn];
//		CPhidgetStepper_getStopped(stepper, Index, &stopped);
        flag_stopped=stopped;
		[stoppedCheckBox setState:stopped];
	}
	[pool release];
}

- (void)SpeedChange:(int)Index:(double)speed
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int stopped;
	if(globalIndex == Index) {
		[velocityField setStringValue:[NSString stringWithFormat:@"%0.3f", speed]];
		[velocityTrackBar setDoubleValue:speed];
//		CPhidgetStepper_getStopped(stepper, Index, &stopped);
        flag_stopped=stopped;
		[stoppedCheckBox setState:stopped];
	}
	[pool release];
}

- (void)CurrentChange:(int)Index:(double)current
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if(globalIndex == Index) {
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
 //   NSLog(@"Add phidget");
	int serial = -1, remote = 0;
	NSArray *args = [[NSProcessInfo processInfo] arguments];
	if([args count] > 1)
	{
		if([[args objectAtIndex:1] isEqualToString:@"remote"])
			remote = 1;
		serial = [[args objectAtIndex:[args count]-1] intValue];
		if(serial == 0) serial = -1;
	}
//    NSLog(@"Add phidget ~ 1");
	[phidget_lock lock]; // 
    usleep(1000000);
    NSLog(@"Add phidget ~ a, %d", remote);
    if(remote){
        ;
    
//		CPhidget_openRemote((CPhidgetHandle)stepper, serial, NULL, [[passwordField stringValue] UTF8String]);
    }
	else{
        Phidget_open((PhidgetHandle)stepper);
//		CPhidget_open((CPhidgetHandle)stepper, serial);
    }
 //   NSLog(@"Add phidget ~ b");
    usleep(1000000); //used to solve the multiple stepper issues
    [phidget_lock unlock];
     
}

/*
 * This gets run when the GUI gets displayed
 */


/*- (void)windowWillClose:(NSNotification *)aNotification {
	CPhidget_close((CPhidgetHandle)stepper);
	CPhidget_delete((CPhidgetHandle)stepper);
	stepper = NULL;
	[NSApp terminate:self];
}
 */

- (void)setPicture:(int)version:(Phidget_DeviceID)devid
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *imgPath;
	
	switch(devid)
	{
		case PHIDID_1067:
			imgPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"1063_0" ofType:@"icns"];
			break;
		case PHIDID_1062:
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

static int errorCounter = 0;
-(void) outputError:(const char *)errorString{
    errorCounter++;
    NSAttributedString *outputString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",[NSString stringWithUTF8String:errorString]]
        attributes:@{NSForegroundColorAttributeName: NSColor.controlTextColor}];
    [[errorEventLog textStorage] beginEditing];
    [[errorEventLog textStorage] appendAttributedString:outputString];
    [[errorEventLog textStorage] endEditing];
    
    [errorEventLogCounter setIntValue:errorCounter];
    if(![errorEventLogWindow isVisible])
        [errorEventLogWindow setIsVisible:YES];
}

-(void)errorHandler:(NSArray *)errorEventData{
    const char* errorString = [[errorEventData objectAtIndex:1] UTF8String];
    [self outputError:errorString];
}

-(void)outputLastError {
    const char *errorString;
    char *errorDetailString = NULL;
    size_t errorDetailStringLen = 0;
    PhidgetReturnCode lastErr;
    
    if (!Phidget_getLastError(&lastErr, &errorString, NULL, &errorDetailStringLen)) {
        errorDetailString = malloc(errorDetailStringLen);
        Phidget_getLastError(&lastErr, &errorString, errorDetailString, &errorDetailStringLen);
        [self outputError:errorDetailString];
        free(errorDetailString);
    }
}

- (IBAction)clearErrorLog:(id)sender{
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

- (int) idAxis {
	return m_axis;
}

- (void)updatePosition:(int) npos
{
//	NSLog(@"Npos: %d, %d\n", m_axis, (int)((long long)npos));
	PhidgetStepper_setTargetPosition(stepper, (long long) npos);
	[positionSetTextBox setIntValue: npos];
	[positionSetTrackBar setIntValue: npos];
}

- (int64_t) getPosition
{
    int64_t cpos;
    
    PhidgetStepper_getPosition(stepper, &cpos);
    return cpos;
}


- (void)onStoppedHandler
{
//    [stoppedCheckBox setSelected: YES];
}

- (void)onVelocityChangeHandler:(NSNumber *)velocity{
    [velocityField setStringValue:[NSString stringWithFormat:@"%.3f",[velocity doubleValue]]];
    [self updateStopped];
}

-(void)updateStopped{
    int isMoving, engaged;
    PhidgetReturnCode result;
    result = PhidgetStepper_getEngaged(stepper, &engaged);
    if(!engaged)
        return;
    result = PhidgetStepper_getIsMoving(stepper, &isMoving);
    if(result != EPHIDGET_OK){
        [self outputLastError];
        return;
    }
    
    if(isMoving){
        ;
 //       [motorMovingLabel setStringValue:@"Moving"];
 //       [motorMovingLabel setBackgroundColor:[NSColor colorWithRed:0 green:0.561 blue:0 alpha:1]];
    }
    else{
        ;
 //       [motorMovingLabel setStringValue:@"Stopped"];
//  [motorMovingLabel setBackgroundColor:[NSColor  colorWithRed:1.0 green:0.494 blue:0.475 alpha:1]];
    }
}

- (void)onPositionChangeHandler:(NSNumber *)position{
    [currentPositionSetTextBox setStringValue:[NSString stringWithFormat:@"%.3f",[position doubleValue]]];
    [currentPositionSetTrackBar setIntValue: [position intValue]];
    [self updateStopped];
}

@end
