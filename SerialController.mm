//
//  SerialController.m
//  bacttrack
//
//  Created by Bin Liu on 8/23/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import "SerialController.h"
#import "AMSerialPortList.h"
#import "AMSerialPortAdditions.h"

@implementation SerialController

- (id)init {
	if (self = [super init]) {
		m_WaitTime=0.01;
	}
    

	return self;
}

- (void)awakeFromNib
{
	[deviceTextField setStringValue:@"/dev/cu.modem"]; // internal modem
	[inputTextField setStringValue: @"ati"]; // will ask for modem type
	
	// register for port add/remove notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddPorts:) name:AMSerialPortListDidAddPortsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemovePorts:) name:AMSerialPortListDidRemovePortsNotification object:nil];
	[AMSerialPortList sharedPortList]; // initialize port list to arm notifications
	float ratioxydefault=1.;
	float ratiozdefault=10.;
	[m_scale_text setFloatValue: unit_xlen];
	[m_scale_tracker setMinValue: 0.1*ratioxydefault];
	[m_scale_tracker setMaxValue: 10.*ratioxydefault];
	[m_scale_tracker setFloatValue:unit_xlen];
	
	[m_focus_text setFloatValue: unit_zlen];
	[m_focus_tracker setMinValue: 0.1*ratiozdefault];
	[m_focus_tracker setMaxValue: 10.*ratiozdefault];
	[m_focus_tracker setFloatValue:unit_zlen];
	[waitTextField setStringValue: [NSString stringWithFormat:@"%.3f", m_WaitTime] ];
    
    [m_serial_x setIntValue: pserial[0]];
    [m_serial_y setIntValue: pserial[1]];
    [m_serial_z setIntValue: pserial[2]];
}


- (AMSerialPort *)port
{
    return port;
}

- (void)setPort:(AMSerialPort *)newPort
{
    id old = nil;
	
    if (newPort != port) {
        old = port;
        port = [newPort retain];
        [old release];
    }
}


- (void)initPort
{
	NSString *deviceName = [deviceTextField stringValue];

	if (![deviceName isEqualToString:[port bsdPath]]) {
		[port close];
		
		[self setPort:[[[AMSerialPort alloc] init:deviceName withName:deviceName type:(NSString*)CFSTR(kIOSerialBSDModemType)] autorelease]];
		
		// register as self as delegate for port
		[port setDelegate:self];
		
		[outputTextView insertText:@"attempting to open port\r"];
		[outputTextView setNeedsDisplay:YES];
		[outputTextView displayIfNeeded];
		
		// open port - may take a few seconds ...
		if ([port open]) {
			
			[outputTextView insertText:@"port opened\r"];
			[outputTextView setNeedsDisplay:YES];
			[outputTextView displayIfNeeded];
			m_BaudRate= [baudTextField intValue];
			[port setSpeed: m_BaudRate];
			m_WaitTime= [waitTextField floatValue];
			[port setReadTimeout: 1];
			// listen for data in a separate thread
//			[port readDataInBackground]; // will be used later
			
			[port writeString:@"DATE\r" usingEncoding:NSUTF8StringEncoding error:NULL];
			NSString *receiveString = [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL];
			if (receiveString) {
				[outputTextView setString: receiveString];
//				[receiveString release];
				[port setReadTimeout: m_WaitTime];
				[m_speedxy setEnabled: YES];
				[m_speedz setEnabled: YES];
				[m_accelxy setEnabled: YES];
				[m_accelz setEnabled: YES];
				[port writeString: [NSString stringWithFormat:@"SMS\r"]  usingEncoding:NSUTF8StringEncoding error:NULL];
				speedxy = [ [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL] intValue];
				[port writeString: [NSString stringWithFormat:@"SMZ\r"]  usingEncoding:NSUTF8StringEncoding error:NULL];
				speedz = [ [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL] intValue];	
				[port writeString: [NSString stringWithFormat:@"SAS\r"]  usingEncoding:NSUTF8StringEncoding error:NULL];
				accelxy = [ [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL] intValue];
				[port writeString: [NSString stringWithFormat:@"SAZ\r"]  usingEncoding:NSUTF8StringEncoding error:NULL];
				accelz = [ [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL] intValue];
				[m_speedxy setStringValue: [NSString stringWithFormat:@"%d", speedxy]];
				[m_speedz setStringValue: [NSString stringWithFormat:@"%d", speedz]];
				[m_accelxy setStringValue: [NSString stringWithFormat:@"%d", accelxy]];
				[m_accelz setStringValue: [NSString stringWithFormat:@"%d", accelz]];
				
				[port writeString: [NSString stringWithFormat:@"P\r"]  usingEncoding:NSUTF8StringEncoding error:NULL];
				receiveString = [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL];
				NSArray *pos=[ receiveString componentsSeparatedByString:@","];
				if(pos){
					stage_x=[[pos objectAtIndex: 0] intValue];
					stage_y=[[pos objectAtIndex: 1] intValue];
					stage_z=[[pos objectAtIndex: 2] intValue];
				}
				else{
					
				}
				[m_posx setIntValue: stage_x]; [m_posx setEnabled: YES];
				[m_posy setIntValue: stage_y]; [m_posy setEnabled: YES];
				[m_posz	setIntValue: stage_z]; [m_posz setEnabled: YES];
				[m_scale_text setFloatValue: unit_xlen]; [m_scale_text setEnabled: YES];
/*				[port writeString: [NSString stringWithFormat:@"SMS,%d", speedxy]  usingEncoding:NSUTF8StringEncoding error:NULL];
				[outputTextView setString: [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL]];
				[port writeString: [NSString stringWithFormat:@"SMS,%d", speedxy]  usingEncoding:NSUTF8StringEncoding error:NULL];
				[outputTextView setString: [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL]];
*/			}
			else{
				[outputTextView setString: @"Connection error! (reset baudrate?)"];
			}
			
		} else { // an error occured while creating port
			[outputTextView insertText:@"couldn't open port for device "];
			[outputTextView insertText:deviceName];
			[outputTextView insertText:@"\r"];
			[outputTextView setNeedsDisplay:YES];
			[outputTextView displayIfNeeded];
			[self setPort:nil];
		}
	}
}


- (void)serialPortReadData:(NSDictionary *)dataDictionary
{
	// this method is called if data arrives 
	// @"data" is the actual data, @"serialPort" is the sending port
	AMSerialPort *sendPort = [dataDictionary objectForKey:@"serialPort"];
	NSData *data = [dataDictionary objectForKey:@"data"];
	if ([data length] > 0) {
		NSString *text = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		[outputTextView insertText:text];
		[text release];
		// continue listening
		[sendPort readDataInBackground];
	} else { // port closed
		[outputTextView insertText:@"port closed\r"];
	}
	[outputTextView setNeedsDisplay:YES];
	[outputTextView displayIfNeeded];
}


- (void)didAddPorts:(NSNotification *)theNotification
{
	[outputTextView insertText:@"didAddPorts:"];
	[outputTextView insertText:@"\r"];
	[outputTextView insertText:[[theNotification userInfo] description]];
	[outputTextView insertText:@"\r"];
	[outputTextView setNeedsDisplay:YES];
}

- (void)didRemovePorts:(NSNotification *)theNotification
{
	[outputTextView insertText:@"didRemovePorts:"];
	[outputTextView insertText:@"\r"];
	[outputTextView insertText:[[theNotification userInfo] description]];
	[outputTextView insertText:@"\r"];
	[outputTextView setNeedsDisplay:YES];
}


- (IBAction)listDevices:(id)sender
{
	// get an port enumerator
	NSEnumerator *enumerator = [AMSerialPortList portEnumerator];
	AMSerialPort *aPort;
	while (aPort = [enumerator nextObject]) {
		// print port name
		[outputTextView insertText:[aPort name]];
		[outputTextView insertText:@":"];
		[outputTextView insertText:[aPort bsdPath]];
		[outputTextView insertText:@"\r"];
	}
	[outputTextView setNeedsDisplay:YES];
}

- (IBAction)chooseDevice:(id)sender
{
	// new device selected
	[self initPort];
}

- (IBAction)dismissDevice:(id)sender
{
	// device unselected
	[port close];
	port=nil;
}

- (IBAction)linkDevice:(id)sender{

	if (!port) {
		[self chooseDevice: sender];
		[m_button_device setTitle: @"Disconnect"];
	}
	else {
		[self dismissDevice: sender];
		[m_button_device setTitle: @"Connect"];
	}
}

- (IBAction)send:(id)sender
{
	NSString *sendString = [[inputTextField stringValue] stringByAppendingString:@"\r"];
	NSString *receiveString;
	
	if(!port) {
		// open a new port if we don't already have one
		[self initPort];
	}
	
	if([port isOpen]) { // in case an error occured while opening the port
		[port writeString:sendString usingEncoding:NSUTF8StringEncoding error:NULL];
		receiveString = [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL];
		[outputTextView setString: receiveString];
	}
}

- (IBAction)applySetting:(id)sender {
	
	if (speedxy != [m_speedxy intValue]){
		[port writeString: [NSString stringWithFormat:@"SMS %d\r", speedxy = [m_speedxy intValue]]  usingEncoding:NSUTF8StringEncoding error:NULL];
		[outputTextView setString: [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL]];
	}
	if (speedz != [m_speedz intValue]){
		[port writeString: [NSString stringWithFormat:@"SMZ %d\r", speedz = [m_speedz intValue]]  usingEncoding:NSUTF8StringEncoding error:NULL];
		[outputTextView setString: [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL]];
	}
	if (accelxy != [m_accelxy intValue]){
		[port writeString: [NSString stringWithFormat:@"SAS %d\r", accelxy = [m_speedxy intValue]]  usingEncoding:NSUTF8StringEncoding error:NULL];
		[outputTextView setString: [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL]];
	}
	if (accelz != [m_accelz intValue]){
		[port writeString: [NSString stringWithFormat:@"SAZ %d\r", accelz = [m_speedz intValue]]  usingEncoding:NSUTF8StringEncoding error:NULL];
		[outputTextView setString: [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL]];
	}
	
	if (stage_x!= [m_posx intValue] | stage_y != [m_posy intValue] | stage_z != [m_posz intValue]){
		[port writeString: [NSString stringWithFormat:@"G %d,%d,%d\r", stage_x = [m_posx intValue], stage_y = [m_posy intValue], stage_z = [m_posz intValue]]
					usingEncoding:NSUTF8StringEncoding 
					error:NULL];
		[outputTextView setString: [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL]];
	}
	unit_xlen=[m_scale_text floatValue];
	unit_zlen=[m_focus_text floatValue];
	[m_scale_tracker setFloatValue: unit_xlen];
	[m_focus_tracker setFloatValue: unit_zlen];
    pserial[0] = [m_serial_x intValue];
    pserial[1] = [m_serial_y intValue];
    pserial[2] = [m_serial_z intValue];
    
    NSString* currPath=[[NSBundle mainBundle] bundlePath];
    NSString* ssfile = [currPath stringByAppendingFormat:@"/../stgserial.txt" ];
    FILE *infile=fopen([ssfile UTF8String ], "w");
    if(infile){
        for (int ii=0; ii<3; ii++){
            fprintf(infile, "%d\n", pserial[ii]);
        }
        fclose(infile);
    }
    
}

- (IBAction)applySettingOut:(id)sender {
	[self applySetting: sender];
	[window orderOut: nil];
}

- (void) thread_stage {
//	NSAutoreleasePool *poolport = [[NSAutoreleasePool alloc] init];
//	[port readDataInBackground];
	NSLog(@"stage thread: %d", flagstage);
	while (flagstage) {
//	if (flagstage) {
		int changex=floor(unit_xlen*((float)target_x-actual_x)/(float)speedxy);
		int changey=floor(unit_xlen*((float)target_y-actual_y)/(float)speedxy);
		int changez=floor(unit_zlen*((float)target_z-actual_z)/(float)speedz);
		NSLog(@"stage on %ld, %d, %d, %d\n", port, changex, changey, changez);
		

		if(port && (changez!=0 )){
			NSLog(@"stage on %d, %d, %d, %d\n", port, changex, changey, changez);
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//			stage_x=stage_x+changex; stage_y=stage_y+changey; stage_z=stage_z+changez;
			NSString* sendString=//			[[NSString alloc] initWithFormat:@"G %d, %d, %d\r", stage_x, stage_y, stage_z];
					[[NSString alloc] initWithFormat:@"GR %d, %d, %d\r", changex, changey, changez];
			
			[port writeString: sendString
					usingEncoding:NSUTF8StringEncoding 
					error:NULL];
//			[port stopReadInBackground];
/*			NSString* receiveString = [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL];
			if (receiveString) {
				stage_x=stage_x+changex; stage_y=stage_y+changey; stage_z=stage_z+changez;
			}
*/			
			if([port readStringUsingEncoding: NSUTF8StringEncoding error: NULL])
			{
				[port writeString: @"P\r" usingEncoding:NSUTF8StringEncoding error:NULL];
				//			[port stopReadInBackground];
				NSString* receiveString =[port readStringUsingEncoding: NSUTF8StringEncoding error: NULL];
				
				NSArray *pos=[ receiveString componentsSeparatedByString:@","];
				if(pos){
					stage_x=[[pos objectAtIndex: 0] intValue];
					stage_y=[[pos objectAtIndex: 1] intValue];
					stage_z=[[pos objectAtIndex: 2] intValue];
					actual_z=target_z;
				}
				else{
				}
			}
					
			[sendString release];
			[pool release];
//			[port readDataInBackground];
//			actual_x=target_x; actual_y=target_y; 
		}
		else if (port && (changex!=0 || changey!=0))
		{
			NSLog(@"stage on %d, %d, %d, %d\n", port, changex, changey, changez);
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			//			stage_x=stage_x+changex; stage_y=stage_y+changey; stage_z=stage_z+changez;
			NSString* sendString=//			[[NSString alloc] initWithFormat:@"G %d, %d, %d\r", stage_x, stage_y, stage_z];
			[[NSString alloc] initWithFormat:@"GR %d, %d\r", changex, changey];
			
			[port writeString: sendString
				usingEncoding:NSUTF8StringEncoding 
						error:NULL];
			//			[port stopReadInBackground];
			/*			NSString* receiveString = [port readStringUsingEncoding: NSUTF8StringEncoding error: NULL];
			 if (receiveString) {
			 stage_x=stage_x+changex; stage_y=stage_y+changey; stage_z=stage_z+changez;
			 }
			 */			
			if([port readStringUsingEncoding: NSUTF8StringEncoding error: NULL])
			{
				[port writeString: @"PS\r" usingEncoding:NSUTF8StringEncoding error:NULL];
				//			[port stopReadInBackground];
				NSString* receiveString =[port readStringUsingEncoding: NSUTF8StringEncoding error: NULL];
				
				NSArray *pos=[ receiveString componentsSeparatedByString:@","];
				if(pos){
					stage_x=[[pos objectAtIndex: 0] intValue];
					stage_y=[[pos objectAtIndex: 1] intValue];
				}
				else{
				}
			}
			
			[sendString release];
			[pool release];
			//			[port readDataInBackground];
//			actual_x=target_x; actual_y=target_y; actual_z=target_z;
		}
	}
//	[port stopReadInBackground];
//	[poolport release];
}

- (void) update_axis:(int)id_axis{
	switch (id_axis) {
		case 1: //x axis
			if ([m_stepper_1 idAxis]==1){
				[m_stepper_1 updatePosition: target_x];
			}
			else if ([m_stepper_2 idAxis]==1){
				[m_stepper_2 updatePosition: target_x];
			}
			else if ([m_stepper_3 idAxis]==1){
				[m_stepper_3 updatePosition: target_x];
			}
			else {
				
			}
//			NSLog(@"x axis updated: %d\n", (int)target_x);
			break;
		case 2: //y axis
			if ([m_stepper_1 idAxis]==2){
					[m_stepper_1 updatePosition: target_y];
			//	NSLog(@"y axis updated: %d, %d\n", (int)m_stepper_1, target_y);
			}
			else if ([m_stepper_2 idAxis]==2){
					[m_stepper_2 updatePosition: target_y];
			//	NSLog(@"y axis updated: %d, %d\n", (int)m_stepper_2, target_y);
			}
			else if ([m_stepper_3 idAxis]==2){
					[m_stepper_3 updatePosition: target_y];
			//	NSLog(@"y axis updated: %d, %d\n", (int)m_stepper_3, target_y);
			}
			else {
				
			}
//			NSLog(@"y axis updated: %d\n", (int)target_y);	
		case 3: //z axis
			if ([m_stepper_1 idAxis]==3){
					[m_stepper_1 updatePosition: target_z];
			}
			else if ([m_stepper_2 idAxis]==3){
					[m_stepper_2 updatePosition: target_z];
			}
			else if ([m_stepper_3 idAxis]==3){
					[m_stepper_3 updatePosition: target_z];
			}
			else {
				
			}
//			NSLog(@"z axis updated: %d\n", (int)target_z);	
		default:
			break;
				
	}
}

- (void) update_axis:(int)id_axis : (long long *) currpos{
	switch (id_axis) {
		case 1: //x axis
			if ([m_stepper_1 idAxis]==1){
                actual_x=[m_stepper_1 getPosition];
				[m_stepper_1 updatePosition: target_x];
                
			}
			else if ([m_stepper_2 idAxis]==1){
                actual_x=[m_stepper_2 getPosition];
				[m_stepper_2 updatePosition: target_x];
                
			}
			else if ([m_stepper_3 idAxis]==1){
                actual_x=[m_stepper_3 getPosition];
				[m_stepper_3 updatePosition: target_x];
                
			}
			else {
				
			}
            //			NSLog(@"x axis updated: %d\n", (int)target_x);
			break;
		case 2: //y axis
			if ([m_stepper_1 idAxis]==2){
                actual_y=[m_stepper_1 getPosition];
                [m_stepper_1 updatePosition: target_y];
                
                //	NSLog(@"y axis updated: %d, %d\n", (int)m_stepper_1, target_y);
			}
			else if ([m_stepper_2 idAxis]==2){
                actual_y=[m_stepper_2 getPosition];
                [m_stepper_2 updatePosition: target_y];
                
                //	NSLog(@"y axis updated: %d, %d\n", (int)m_stepper_2, target_y);
			}
			else if ([m_stepper_3 idAxis]==2){
                actual_y=[m_stepper_3 getPosition];
                [m_stepper_3 updatePosition: target_y];
                
                //	NSLog(@"y axis updated: %d, %d\n", (int)m_stepper_3, target_y);
			}
			else {
				
			}
		case 3: //z axis
			if ([m_stepper_1 idAxis]==3){
                actual_z0=actual_z;
                actual_z=[m_stepper_1 getPosition];
                if ((actual_z0-actual_z)*(actual_z-target_z)<0){
                    if (actual_z>target_z) {
                        [m_stepper_1 updatePosition: target_z-stp_backlash];
                    }
                    else{
                        [m_stepper_1 updatePosition: target_z+stp_backlash];
                    }
                }
                else{
                    [m_stepper_1 updatePosition: target_z];
                }
			}
			else if ([m_stepper_2 idAxis]==3){
                actual_z0=actual_z;
                actual_z=[m_stepper_2 getPosition];
                if ((actual_z0-actual_z)*(actual_z-target_z)<0){
                    if (actual_z>target_z) {
                        [m_stepper_2 updatePosition: target_z-stp_backlash];
                    }
                    else{
                        [m_stepper_2 updatePosition: target_z+stp_backlash];
                    }
                }
                else{
                    [m_stepper_2 updatePosition: target_z];
                }
			}
			else if ([m_stepper_3 idAxis]==3){
                actual_z0=actual_z;
                actual_z=[m_stepper_3 getPosition];
                if ((actual_z0-actual_z)*(actual_z-target_z)<0){
                    if (actual_z>target_z) {
                        [m_stepper_3 updatePosition: target_z-stp_backlash];
                    }
                    else{
                        [m_stepper_3 updatePosition: target_z+stp_backlash];
                    }
                }
                else{
                    [m_stepper_3 updatePosition: target_z];
                }                
			}
			else {
				
			}
		default:
			break;
            
            
	}
}

- (void) trigger_stage {
//	NSLog("Stepper: %d, %d, %d", (int)m_stepper_1, (int)m_stepper_2, (int)m_stepper_3);
    
	if (target_x != actual_x)
    {
        [self update_axis: 1: NULL] ;
    }
    if (target_y != actual_y){
        [self update_axis: 2: NULL] ;
	}
/*    if (target_piezo!= actual_piezo)
    {

        if (target_piezo>target_piezo_min && target_piezo<target_piezo_max)
        {
            [self update_piezoz: target_piezo]; 
        }
    }
 */
//    NSLog(@"currentpos: %lld, %lld, %lld", actual_x, actual_y, actual_z);
/*    [stage_lock lock];
    actual_x = target_x;
    actual_y = target_y;
    actual_z = target_z;
    [stage_lock unlock];
 */
}

- (void) trigger_piezo {
    
    if (target_piezo>target_piezo_min && target_piezo<target_piezo_max)
    {
        [self update_piezoz: target_piezo]; 
    }
}

- (IBAction)ControlStage:(id)sender {
	
//	NSLog(@"controlstage: %d, %d\n", flagstage, [m_control_swith isSelectedForSegment:0]);
	if (!flagstage & [m_control_swith isSelectedForSegment:0] ) {
//		[port readDataInBackground];
		
//		[NSThread detachNewThreadSelector: @selector(thread_stage) toTarget:self withObject: nil];
		NSLog(@"Control on!");
		
		trig_control = [NSTimer scheduledTimerWithTimeInterval:m_WaitTime //0.01
													   target:self 
													 selector:@selector(trigger_stage) //selector:@selector(trigger_piezo)
													 userInfo:nil 
													  repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:trig_control forMode:NSRunLoopCommonModes];
        trig_piezoz = [NSTimer scheduledTimerWithTimeInterval:m_WaitTime //0.01
                                                        target:self
                                                     selector:@selector(trigger_piezo)
                                                      userInfo:nil 
                                                       repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:trig_piezoz forMode:NSRunLoopCommonModes];
		flagstage = TRUE;
		[m_control_swith setSelectedSegment: 0];
	}
	else if (flagstage & [m_control_swith isSelectedForSegment:1]) { 
		
		[trig_control invalidate];
        [trig_piezoz invalidate];
		trig_control=nil;
        trig_piezoz=nil;
		flagstage = FALSE;
		[m_control_swith setSelectedSegment: 1];
		
	}
    
}

- (IBAction) setxyRatioBox: (id)sender{
	unit_xlen = [sender floatValue];
	[m_scale_tracker setDoubleValue: unit_xlen];
	 
}

- (IBAction) setxyRatioTracker: (id)sender{
	unit_xlen = [sender floatValue];
	[m_scale_text setDoubleValue: unit_xlen];
}

- (IBAction) setzRatioBox: (id)sender{
	unit_zlen = [sender floatValue];
	[m_focus_tracker setDoubleValue: unit_zlen];
}

- (IBAction) setzRatioTracker: (id)sender{
	unit_zlen = [sender floatValue];
	[m_focus_text setDoubleValue: unit_zlen];
}

- (void) update_piezoz: (float) pos_z{
	
	[m_piezoZ setVolt: pos_z];
	[m_piezoZ updateVolt];
}

@end
