//
//  PiezoController.m
//  bacttrack
//
//  Created by Bin Liu on 5/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PiezoController.h"
//#define DAQmxErrChk(functionCall) { if( DAQmxFailed(error=(functionCall)) ) { goto Error; } }

@implementation PiezoController


- (void)windowWillClose:(NSNotification*)aNotification{
    if(zout){
        //Safely close the example
        Phidget_setOnAttachHandler((PhidgetHandle)zout, NULL, NULL);
        Phidget_setOnDetachHandler((PhidgetHandle)zout, NULL, NULL);
        Phidget_setOnErrorHandler((PhidgetHandle)zout, NULL, NULL);
        Phidget_close((PhidgetHandle)zout);
        PhidgetVoltageOutput_delete(&zout);
        zout = NULL;
    }
    if(zin){
        Phidget_setOnAttachHandler((PhidgetHandle)zin, NULL, NULL);
        Phidget_setOnDetachHandler((PhidgetHandle)zin, NULL, NULL);
        Phidget_setOnErrorHandler((PhidgetHandle)zin, NULL, NULL);
        Phidget_close((PhidgetHandle)zin);
        PhidgetVoltageInput_delete(&zin);
        zin = NULL;
    }
}

- (id) init {
	NSLog(@"piezo1 init");
    
	if (self=[super init]){
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		error=0;
//		taskHandle=0;
		errBuff[0]='\0';
		sprintf(chan, "Dev1/ao0");
		sprintf(chan_enc, "Dev1/ai0");
		vmin=0.0;
        
		vmax=10.0;
        calbSize=20;
        calbStep=(vmax-vmin)/(calbSize-1.);
        calbTryNum=100;
        polyOrder=8;
		samplesPerChan=1;
		volt=0.5*(vmax+vmin);
		timeout=10.;
		pointsToRead = 1;
		flag_switch=TRUE;
        sizeBuffer=1000;
        sizeBufferLin=10;
        flag_calib=FALSE;
        driftBuffer = (float*) malloc(sizeof(float)*sizeBuffer);
        exchgStock = (float*) malloc(sizeof(float)*sizeBuffer);
        voltBuffer = (float*) malloc(sizeof(float)*sizeBufferLin);
        timeBuffer = (float*) malloc(sizeof(float)*sizeBufferLin);
        fitCoeff = (float*) malloc(sizeof(float)*(polyOrder+1));
		countBuffer=0;
        countBufferLin=0;
        avgBuffer=0.0;
        bufferavglock = [[NSLock alloc] init];
        voltLock = [[NSLock alloc] init];
        if (!piezo_lock) {
            piezo_lock=[[NSLock alloc] init];
        }
//		DAQmxErrChk ( DAQmxBaseCreateTask("",&taskHandle) );
/*		DAQmxErrChk ( DAQmxBaseCreateAOVoltageChan(taskHandle,chan,"",vmin,vmax,DAQmx_Val_Volts,NULL) );
		DAQmxErrChk ( DAQmxBaseStartTask(taskHandle) );
        if ([voltLock tryLock]){
		DAQmxErrChk ( DAQmxBaseWriteAnalogF64(taskHandle,samplesPerChan,0,timeout,DAQmx_Val_GroupByChannel,&volt,&pointsWritten,NULL) );
            [voltLock unlock];
        }
 */
        if(!startdate){
            startdate=[[NSDate alloc] init];
        }
//		usleep(200000000);
//        volt=0.0;
//		DAQmxErrChk ( DAQmxBaseWriteAnalogF64(taskHandle,samplesPerChan,0,timeout,DAQmx_Val_GroupByChannel,&volt,&pointsWritten,NULL) );
        
	Error:
/*		if( DAQmxFailed(error) )
			DAQmxBaseGetExtendedErrorInfo(errBuff,2048);
		if(taskHandle!=0 ) {
			DAQmxBaseStopTask(taskHandle);
			DAQmxBaseClearTask(taskHandle);
			taskHandle=0;
		}
		if( DAQmxFailed(error) )
			printf ("DAQmxBase Error %d: %s\n", error, errBuff);
  */
        NSString* currPath=[[NSBundle mainBundle] bundlePath];
        NSLog(@"path: %s", [currPath UTF8String]);
        NSString* calfile = [currPath stringByAppendingFormat:@"/../zcalibrate.txt" ];
        FILE *infile=fopen([calfile UTF8String ], "r");
        NSLog(@"file: %d", infile);
        if(infile){
            float vt;
            for (int i=0; i<=polyOrder; i++){
                fscanf(infile, "%e", &vt);
                fitCoeff[i]=vt;
                NSLog(@"i: %d, %f", i, fitCoeff[i]);
 
            }
            if(fabs(fitCoeff[0])>1E-16){
                flag_calib=TRUE;
            }
            fclose(infile);
        }
        [pool release];
	}
    
	return self;
}

- (void)awakeFromNib {
	NSLog(@"Hello piezo");
    
    PhidgetReturnCode result;
    //Manage GUI
    result = PhidgetVoltageOutput_create(&zout);
    if(result != EPHIDGET_OK){
        [self outputLastError];
    }
    
    result = PhidgetVoltageInput_create(&zin);
    if(result != EPHIDGET_OK){
        [self outputLastError];
    }
    
    result = [self initChannel:(PhidgetHandle)zout];
    if(result != EPHIDGET_OK){
        [self outputLastError];
    }
    
    result = [self initChannel:(PhidgetHandle)zin];
    if(result != EPHIDGET_OK){
        [self outputLastError];
    }
    
    NSLog(@"zout: %d, %d", zout, zin);
    [self openCmdLine:(PhidgetHandle)zout];
    [self openCmdLine:(PhidgetHandle)zin];
//    [PhidgetInfoBox openCmdLine:(PhidgetHandle)zout];
	if(!error){
//        Phidget_getDeviceName((PhidgetHandle)zout, &name);
//        NSLog(@"daq name: %d", name);
//		[DAQField setStringValue: [NSString stringWithUTF8String:name]];
		[DAQSlide setEnabled:FALSE];
		[DAQSlide setMinValue: vmin];
		[DAQSlide setMaxValue: vmax];
		[DAQSlide setFloatValue:.5*(vmin+vmax)];
		[DAQScroll setEnabled:FALSE];
		[DAQScroll setMinValue: .5*(vmin+vmax)+0.05*(vmin-vmax)];
		[DAQScroll setMaxValue: .5*(vmin+vmax)+0.05*(vmax-vmin)];
		[DAQScroll setFloatValue:.5*(vmin+vmax)];
		[DAQswitch setEnabled:TRUE];
		[Monswitch setEnabled:TRUE];
		[VolField setStringValue: [NSString stringWithFormat:@"%.3f", volt]];
		[PosField setStringValue:[NSString stringWithFormat: @"%.4f", (volt-.5*(vmax+vmin))*10]];
        [buttonCalib setEnabled: FALSE];

	}
}

- (IBAction) scrollvoltage: (id) sender{
	//NSLog(@"scroll: %f", [sender floatValue]);
	float currVolt=[sender floatValue];
    float newVolt;
    
    if ([voltLock tryLock]){
        newVolt=volt;
        [voltLock unlock];
    }
    else{
        newVolt=currVolt;
    }
	if(newVolt-currVolt>0.05*(vmax-vmin)){
        if ([voltLock tryLock]){
            volt=currVolt+.1*(vmax-vmin);
            newVolt=volt;
            [voltLock unlock];
            target_piezo=newVolt;
        }
		float minscroll = [DAQScroll minValue];
		[DAQScroll setMinValue: minscroll+.1*(vmax-vmin)];
		[DAQScroll setMaxValue: minscroll+.2*(vmax-vmin)];
		[DAQScroll setFloatValue:newVolt];
	}
	else if(newVolt-currVolt<0.05*(vmin-vmax)){
        if ([voltLock tryLock]){
            volt=currVolt-.1*(vmax-vmin);
            newVolt=volt;
            [voltLock unlock];
            target_piezo=newVolt;
        }
		float minscroll = [DAQScroll minValue];
		[DAQScroll setMinValue: minscroll-.1*(vmax-vmin)];
		[DAQScroll setMaxValue: minscroll];
		[DAQScroll setFloatValue:newVolt];
	}
	else {
        if ([voltLock tryLock]){
            volt=currVolt;
            [voltLock unlock];
            target_piezo=currVolt;
        }
	}
	if (volt<0) {
		volt=0;
	}
	else if(volt>vmax){
		volt=vmax;
	}
    
	[DAQSlide setFloatValue:volt];
    /*    if (!flagauto)
     target_piezo=volt;
     */
        
	[self updateVolt];
	//NSLog(@"volt: %f", volt);

}

- (IBAction) slidevoltage: (id) sender{
	volt=[sender floatValue];
	[self updateVolt];
	float winvmin, winvmax;
	winvmin=floor(volt/(.1*(vmax-vmin)))*.1*(vmax-vmin);
	winvmax=winvmin+.1*(vmax-vmin);
	[DAQScroll setMinValue: winvmin];
	[DAQScroll setMaxValue: winvmax];
	[DAQScroll setFloatValue:volt];
/*    if (!flagauto)
        target_piezo=volt;
*/
}

- (void) updateVolt{
//	NSLog(@"task: %d, %d", &taskHandle ,chan);
    instanceVolt=[startdate timeIntervalSinceNow];
    PhidgetReturnCode result;
    
    if (countBufferLin<sizeBufferLin) {
        *(timeBuffer+countBufferLin)=instanceVolt;
        [voltLock lock];
        *(voltBuffer+countBufferLin)=volt;
        [voltLock unlock];
        countBufferLin++;
    }
    else {
        memcpy(exchgStock, voltBuffer, sizeBufferLin*sizeof(float));
        memcpy(voltBuffer, exchgStock+1, (sizeBufferLin-1)*sizeof(float));
        [voltLock lock];
        *(voltBuffer+sizeBufferLin-1)=volt;
        [voltLock unlock];
        memcpy(exchgStock, timeBuffer, sizeBufferLin*sizeof(float));
        memcpy(timeBuffer, exchgStock+1, (sizeBufferLin-1)*sizeof(float));
        *(timeBuffer+sizeBufferLin-1)=instanceVolt;
    }    
//    NSLog(@"update: %lf", volt);
	if(!error && volt>=vmin && volt<=vmax){
        
        result = PhidgetVoltageOutput_setVoltage(zout, volt);
        if(result != EPHIDGET_OK){
            [self outputLastError];
            return;
        }
//		NSLog(@"volt: %f", volt);
	}
Error:
/*	if( DAQmxFailed(error) )
		DAQmxBaseGetExtendedErrorInfo(errBuff,2048);
	if(error && taskHandle!=0 ) {
		DAQmxBaseStopTask(taskHandle);
		DAQmxBaseClearTask(taskHandle);
	}
	if( DAQmxFailed(error) )
		printf ("DAQmxBase Error %d: %s\n", error, errBuff);	
	*/
    
	[VolField setStringValue:[NSString stringWithFormat: @"%.3f", volt]];
    [PosField setStringValue:[NSString stringWithFormat: @"%.4f", (volt-.5*(vmax+vmin))*10]];
    [DAQSlide setFloatValue:volt];
    [DAQScroll setFloatValue:volt];

}

- (IBAction) switchvoltage: (id) sender{

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int enabled;
    PhidgetReturnCode result;
    
    if ( [DAQswitch isSelectedForSegment:0]){ //(!taskHandle && [DAQswitch isSelectedForSegment:0]){
		NSLog(@"piezo on");
        result = PhidgetVoltageOutput_getEnabled(zout, &enabled);
        NSLog(@"enabled: %d", enabled);
        if(!enabled){
            result = PhidgetVoltageOutput_setEnabled(zout, 1);
            if(result != EPHIDGET_OK){
                [self outputLastError];
                return;
            }
        }
    //        [enableButton setTitle:@"Enable"];
        result = PhidgetVoltageOutput_getEnabled(zout, &enabled);
        NSLog(@"enabled: %d", enabled);
        [DAQswitch setSelectedSegment: 0];
        [DAQScroll setEnabled:TRUE];
        [DAQSlide setEnabled:TRUE];
        [buttonCalib setEnabled: TRUE];
        flag_switch=TRUE;
            
        
/*		DAQmxErrChk ( DAQmxBaseCreateTask("",&taskHandle) );
		DAQmxErrChk ( DAQmxBaseCreateAOVoltageChan(taskHandle,chan,"",vmin,vmax,DAQmx_Val_Volts,NULL) );
		DAQmxErrChk ( DAQmxBaseStartTask(taskHandle) );
		DAQmxErrChk ( DAQmxBaseWriteAnalogF64(taskHandle,samplesPerChan,0,timeout,DAQmx_Val_GroupByChannel,&volt,&pointsWritten,NULL) );
		
		DAQmxErrChk (DAQmxBaseCreateTask("",&encoHandle));
		DAQmxErrChk (DAQmxBaseCreateAIVoltageChan(encoHandle,chan_enc,"",DAQmx_Val_Cfg_Default,vmin,vmax,DAQmx_Val_Volts,NULL));
		DAQmxErrChk (DAQmxBaseStartTask(encoHandle));
		
*/
    
        trig_monit = [NSTimer scheduledTimerWithTimeInterval:1/29.97
													   target:self 
													 selector:@selector(getDiffVolt) 
													 userInfo:nil 
													  repeats:YES];

		[NSThread detachNewThreadSelector: @selector(thread_diffVolt) toTarget:self withObject:nil];
		

	}
    else{ //if ([DAQswitch isSelectedForSegment:1]) { //(!taskHandle & [DAQswitch isSelectedForSegment:1]) {
        
		NSLog(@"piezo off");
//		[DAQswitch setSelectedSegment: 1];
        result = PhidgetVoltageOutput_getEnabled(zout, &enabled);
        NSLog(@"enabled: %d", enabled);
        if(enabled){
            result = PhidgetVoltageOutput_setEnabled(zout, 0);
            if(result != EPHIDGET_OK){
                [self outputLastError];
                return;
            }
        }
    //        [enableButton setTitle:@"Enable"];
        [DAQswitch setSelectedSegment: 0];
        [DAQScroll setEnabled:FALSE];
        [DAQSlide setEnabled:FALSE];
        [buttonCalib setEnabled: FALSE];
        flag_switch=FALSE;
        usleep(30000);
//		DAQmxBaseStopTask(taskHandle);
//		DAQmxBaseClearTask(taskHandle);
//		taskHandle=0;
		[trig_monit invalidate];
		trig_monit = nil;
//		if (encoHandle) {
//			DAQmxBaseStopTask(encoHandle);
//			DAQmxBaseClearTask(encoHandle);
//			encoHandle=0;
//		}
	}
 
	[pool release];
}

- (IBAction) switchMonitor: (id) sender{
	
	if(!flag_switch && [Monswitch isSelectedForSegment:0]){
		[Monswitch setSelectedSegment: 0];
		flag_switch=TRUE;
		usleep(30000);
		[NSThread detachNewThreadSelector: @selector(thread_diffVolt) toTarget:self withObject:nil];
	}
	else if ([Monswitch isSelectedForSegment:1]) { 
		[Monswitch setSelectedSegment: 1];
		flag_switch=FALSE;
        usleep(30000);
	}
}


- (void) setVolt: (float) voltvalue{
    [voltLock lock];
	volt=voltvalue;
    [voltLock unlock];
}

- (float) getVolt{
//	DAQmxErrChk (DAQmxBaseCreateTask("",&taskHandle));
//    DAQmxErrChk (DAQmxBaseCreateAIVoltageChan(taskHandle,chan,"",DAQmx_Val_Cfg_Default,vmin,vmax,DAQmx_Val_Volts,NULL));
//    DAQmxErrChk (DAQmxBaseStartTask(taskHandle));
	double vdata;
    float instanceVoltNow;
/*    if (encoHandle) {
		DAQmxBaseReadAnalogF64(encoHandle,pointsToRead,timeout,DAQmx_Val_GroupByChannel,&vdata,samplesPerChan,&pointsRead,NULL);		
	}
 */
    PhidgetReturnCode result;
    
    result = PhidgetVoltageInput_getVoltage(zin, &vdata);
    NSLog(@"Vdata: %f", (float)vdata);
    instanceVoltNow=[startdate timeIntervalSinceNow];
    
//	actual_piezo=vdata;
//    target_piezo=volt;
    float diffV;
    float delayVolt;
    float corrVolt;

    [voltLock lock];
    delayVolt=volt;
    [voltLock unlock];
    
    if(flag_calib)
    {
        corrVolt=fitCoeff[0];
        for(int i=1; i<=polyOrder;i++){
            corrVolt+=fitCoeff[i]*pow((float)vdata, i);
        }
    }
    else
        corrVolt=(float)vdata;
//    NSLog(@"v: %f, %f", vdata, corrVolt);
    [piezo_lock lock];
    actual_piezo = corrVolt;
    [piezo_lock unlock];
    
    diffV=corrVolt-delayVolt;
    
//    NSLog(@"diffV: %f", diffV);
    if (!flag_focus || !flagauto) {
    
    
    if (countBuffer<sizeBuffer) {
        *(driftBuffer+countBuffer)=diffV;
        [bufferavglock lock];
        avgBuffer=(avgBuffer*countBuffer+diffV)/(++countBuffer);
        [bufferavglock unlock];
    }
    else {
        memcpy(exchgStock, driftBuffer, sizeBuffer*sizeof(float));
        [bufferavglock lock];
        avgBuffer=(avgBuffer*sizeBuffer-(*driftBuffer)+diffV)/(float)sizeBuffer;
        [bufferavglock unlock];
        memcpy(driftBuffer, exchgStock+1, (sizeBuffer-1)*sizeof(float));
        *(driftBuffer+sizeBuffer-1)=diffV;
    }
    }
//	NSLog(@"actual_voltage: %f", vdata);
	return corrVolt;
}

- (float) getPanelVolt{
    
	return volt;
}

- (float) getDrift{
    float avgdata;
    [bufferavglock lock];
//    NSLog(@"avergebuffer: %f", avgBuffer);
    avgdata=avgBuffer;
    [bufferavglock unlock];
    return avgdata;
}

- (void) getDiffVolt{
	float diffV=[self getVolt]-volt;
//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	char signV=(diffV>=0?'+':'-');
	[VdiffField setStringValue: [NSString stringWithFormat:@"%c%.5f", signV, fabs(diffV)]];
    [VdiffField setNeedsDisplay: YES];
//	[pool release];
//    NSLog(@"date: %lf", [startdate timeIntervalSinceNow]);
}

- (void) thread_diffVolt{
	while (flag_switch){
		[self getDiffVolt];
//		usleep(5000);
	}
}

- (bool) MonitorStatus{
	return flag_switch;
}

- (void) dealloc{
    if (driftBuffer)
        free(driftBuffer);
    if (exchgStock)
        free(exchgStock);
    [super dealloc];
}

- (IBAction) calibrateVolt: (id) sender{
    static float* calbVoltIn=NULL;
    static float* calbVoltOut=NULL;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if(flag_switch){
        flag_switch=FALSE;
        usleep(30000);
    }
    flag_calib=FALSE;
    [DAQSlide setEnabled:FALSE];
    [DAQScroll setEnabled:FALSE];
    [DAQswitch setEnabled:FALSE];
    [Monswitch setEnabled:FALSE];
    [buttonCalib setEnabled: FALSE];
    
    if(!calbVoltIn){
        calbVoltIn = (float*) malloc(sizeof(float)*calbSize);
    }
    if(!calbVoltOut){
        calbVoltOut = (float*) malloc(sizeof(float)*calbSize);
    }
        
    for(int i=0; i<calbSize; i++){
        volt=vmin+(float)i*calbStep;
        [self updateVolt];
        calbVoltIn[i]=volt;
        usleep(10000);
        float sumVolt=0.0;
        for(int j=0; j<calbTryNum; j++){
            sumVolt=sumVolt+[self getVolt];
            usleep(10000);
        }
        calbVoltOut[i]=sumVolt/(float)calbTryNum;
    }
    for(int i=calbSize-1; i>=0; i--){
        volt=vmin+(float)i*calbStep;
        [self updateVolt];
        usleep(10000);
        float sumVolt=0.0;
        for(int j=0; j<calbTryNum; j++){
            sumVolt=sumVolt+[self getVolt];
            usleep(10000);
        }
        calbVoltOut[i]=.5*(calbVoltOut[i]+sumVolt/(float)calbTryNum);
//        NSLog(@"calib:%lf, %lf", calbVoltIn[i], calbVoltOut[i]);
    }
    volt=0.5*(vmax+vmin);
    [self updateVolt];
//    polynomialFit(calbVoltOut, calbVoltIn, calbSize, fitCoeff, polyOrder);
    [self polynomialFit:calbSize x:calbVoltOut y:calbVoltIn dst:fitCoeff];
    for(int i=0; i<=polyOrder; i++){
        NSLog(@"poly: %d, coef: %lf", i, fitCoeff[i]);
    }
    NSString* currPath=[[NSBundle mainBundle] bundlePath];
    NSLog(@"path: %s", [currPath UTF8String]);
    NSString* calfile = [currPath stringByAppendingFormat:@"/../zcalibrate.txt" ];
    FILE *outfile=fopen([calfile UTF8String ], "w");
    NSLog(@"file: %d", outfile);
    
    //     NSLog(@"%s, %d, %d\n", [logName UTF8String], outfile, time_i[0]);
    //        NSLog(@"save: %d", (int) data_counter);
    for (int i=0; i<=polyOrder; i++){
        fprintf(outfile, "%e\n", fitCoeff[i]);
    }
    fclose(outfile);
    [DAQSlide setEnabled:TRUE];
    [DAQScroll setEnabled:TRUE];
    [DAQswitch setEnabled:TRUE];
    [Monswitch setEnabled:TRUE];
    [buttonCalib setEnabled: TRUE];
    [pool release];
}

- (void) polynomialFit: (size_t) size_data x: (float*) xdata y: (float*) ydata dst: (float*) polyCoeff
{
    flag_calib=FALSE;
    float* pA=(float*) malloc(sizeof(float)*(polyOrder+1)*(polyOrder+1));
    float* pB=(float*) malloc(sizeof(float)*(polyOrder+1));
    CvMat matA=cvMat(polyOrder+1, polyOrder+1, CV_64F, pA);
    CvMat matB=cvMat(polyOrder+1, 1, CV_64F, pB);
    CvMat matX=cvMat(polyOrder+1, 1, CV_64F, polyCoeff);
    
    for(int i=0; i<=polyOrder; i++)
    {
        float sumB=0.0;
        for(int j=0; j<size_data; j++)
        {
            sumB+=ydata[j]*pow(xdata[j],i);
        }  
        pB[i]=sumB;
    }
    
    for(int i=0; i<=polyOrder; i++)
    {
        for(int k=0; k<=polyOrder; k++)
        {
            float sumA=0.0;
            for(int j=0; j<size_data; j++)
            {
                sumA+=pow(xdata[j], i+k);
            }
            *(pA+(polyOrder+1)*i+k)=sumA;
        }
    }
    
    cvSolve(&matA, &matB, &matX, CV_LU);
    free(pA);
    free(pB);
    flag_calib=TRUE;
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

#pragma mark Event callbacks]
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

#pragma mark Attach, detach, and error events
- (void)onAttachHandler{
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    double minVoltage,maxVoltage, voltage;
    Phidget_DeviceID deviceID, deviceIDin;
    const char* name;
    int enabled;
    PhidgetVoltageOutput_VoltageOutputRange voltageOutputRange;
    
    //Get information from channel that will allow us to configure the GUI properly
    Phidget_getDeviceID((PhidgetHandle)zout, &deviceID);
    PhidgetVoltageOutput_getMinVoltage(zout, &minVoltage);
    PhidgetVoltageOutput_getMaxVoltage(zout, &maxVoltage);
    PhidgetVoltageOutput_getVoltage(zout, &voltage);
    PhidgetVoltageOutput_getEnabled(zout, &enabled);
    PhidgetVoltageOutput_getVoltageOutputRange(zout, &voltageOutputRange);
    PhidgetVoltageOutput_setVoltageOutputRange(zout, VOLTAGE_OUTPUT_RANGE_10V);
    Phidget_getDeviceName((PhidgetHandle) zout, &name);
    
    
    Phidget_getDeviceID((PhidgetHandle)zin, &deviceIDin);
    
    NSLog(@"daq id: %d", deviceIDin);
    //Adjust GUI based on information from the channel
//    [phidgetInfoBoxView fillPhidgetInfo:(PhidgetHandle)zout];
//    [outputBox setHidden:NO];
    
    switch(deviceID){
        case PHIDID_1002:
        case PHIDID_OUT1000:
/*            [outputModeBox setHidden:YES];
            [outputEnableBox setHidden:NO];
            [enableButton setIntValue:enabled];
            if(enabled){
                [enableButton setTitle:@"Disable"];
            }
            else{
                [enableButton setTitle:@"Enable"];
            }
 */
            break;
        case PHIDID_OUT1001:
        case PHIDID_OUT1002:
 //           [outputModeBox setHidden:NO];
            [DAQField setStringValue: [[NSString stringWithUTF8String:name] substringToIndex:20]];
            break;
        default:
            break;
    }
    
    //Configure voltage output slider with information read from channel
 /*   [voltageOutputSlider setMaxValue:maxVoltage];
    [voltageOutputSlider setMinValue:minVoltage];
    [voltageOutputSlider setDoubleValue:voltage];
    [voltageOutputMinLabel setStringValue:[NSString stringWithFormat:@"%.2f",minVoltage]];
    [voltageOutputMaxLabel setStringValue:[NSString stringWithFormat:@"%.2f",maxVoltage]];
    [voltageOutputText setStringValue:[NSString stringWithFormat:@"%.2f V",voltage]];
    
    //Configure voltage output button based on information read from channel
    if(voltageOutputRange == VOLTAGE_OUTPUT_RANGE_5V){
        [voltageModeButton setTitle:@"Switch to 10V"];
    }
    else if(voltageOutputRange == VOLTAGE_OUTPUT_RANGE_10V){
        [voltageModeButton setTitle:@"Switch to 5V"];
    }

    //Adjusting window height
    NSRect frame = [mainWindow frame];
    frame.size.height = [mainWindow maxSize].height;
    [mainWindow setFrame:frame display:NO];
    [mainWindow center];
  */
    [pool release];
}
- (void)onDetachHandler{
    //Reset
/*    [outputBox setHidden:YES];
    [outputModeBox setHidden:YES];
    [outputEnableBox setHidden:YES];
    [voltageOutputText setStringValue:@""];
    [phidgetInfoBoxView fillPhidgetInfo:nil];
    
    //Adjusting window height
    NSRect frame = [mainWindow frame];
    frame.size.height = [mainWindow minSize].height;
    [mainWindow setFrame:frame display:NO];
    [mainWindow center];
 */
    [DAQField setStringValue: [NSString stringWithUTF8String:"Not detected"] ];
}

static int errorCounter = 0;
-(void) outputError:(const char *)errorString{
    errorCounter++;
    NSAttributedString *outputString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",[NSString stringWithUTF8String:errorString]]
        attributes:@{NSForegroundColorAttributeName: NSColor.controlTextColor}];
 /*   [[errorEventLog textStorage] beginEditing];
    [[errorEventLog textStorage] appendAttributedString:outputString];
    [[errorEventLog textStorage] endEditing];
    
    [errorEventLogCounter setIntValue:errorCounter];
    if(![errorEventLogWindow isVisible])
        [errorEventLogWindow setIsVisible:YES];
*/
    
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
        errorDetailString = (char *) malloc(errorDetailStringLen);
        Phidget_getLastError(&lastErr, &errorString, errorDetailString, &errorDetailStringLen);
        [self outputError:errorDetailString];
        free(errorDetailString);
    }
}

- (IBAction)clearErrorLog:(id)sender{
//    [[errorEventLog textStorage] setAttributedString:[[NSAttributedString alloc] initWithString:@""]];
//    [errorEventLogCounter setIntValue:0];
    errorCounter = 0;
}

#pragma mark GUI controls
- (IBAction)setEnabled:(id)sender{
    PhidgetReturnCode result;
    int enabled;
    
    result = PhidgetVoltageOutput_getEnabled(zout, &enabled);
    if(result != EPHIDGET_OK){
        [self outputLastError];
        return;
    }
    
    if(enabled){
        result = PhidgetVoltageOutput_setEnabled(zout, 0);
        if(result != EPHIDGET_OK){
            [self outputLastError];
            return;
        }
//        [enableButton setTitle:@"Enable"];
        [DAQswitch setSelectedSegment: 0];
        [DAQScroll setEnabled:TRUE];
        [DAQSlide setEnabled:TRUE];
        [buttonCalib setEnabled: TRUE];
    }
    else{
        result = PhidgetVoltageOutput_setEnabled(zout, 1);
        if(result != EPHIDGET_OK){
            [self outputLastError];
            return;
        }
        [DAQswitch setSelectedSegment: 1];
        [DAQScroll setEnabled:FALSE];
        [DAQSlide setEnabled:FALSE];
        [buttonCalib setEnabled: FALSE];
    }
}

- (IBAction)setVoltage:(id)sender{
    PhidgetReturnCode result;
//    result = PhidgetVoltageOutput_setVoltage(zout, [voltageOutputSlider doubleValue]);
    if(result != EPHIDGET_OK){
        [self outputLastError];
        return;
    }
//    [voltageOutputText setStringValue:[NSString stringWithFormat:@"%0.2f V", [voltageOutputSlider doubleValue]]];
}

-(void)openCmdLine:(PhidgetHandle)phid{
    BOOL isHubPort = NO, remote = NO, errorOccurred = NO;
    PhidgetReturnCode result;

    NSArray *args = [[NSProcessInfo processInfo] arguments];
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger serialNumber = [standardDefaults integerForKey:@"n"];
    NSString *logfile = [standardDefaults stringForKey:@"l"];
    NSInteger hubPort = [standardDefaults integerForKey:@"v"];
    NSInteger deviceChannel = [standardDefaults integerForKey:@"c"];
    NSString *serverName = [standardDefaults stringForKey:@"s"];
    NSString *password = [standardDefaults stringForKey:@"p"];
    NSString *deviceLabel = [standardDefaults stringForKey:@"L"];
    remote = [standardDefaults boolForKey:@"r"];
    isHubPort = [standardDefaults boolForKey:@"h"];

    int i = 0;
    for(NSString *arg in args){
        i++;
        if([arg isEqualToString:@"n"]){
            serialNumber = [[args objectAtIndex:i] intValue];
        }
        else if([arg isEqualToString:@"l"]){
            logfile = [args objectAtIndex:i];
        }
        else if([arg isEqualToString:@"v"]){
            hubPort = [[args objectAtIndex:i] intValue];
        }
        else if([arg isEqualToString:@"c"]){
            deviceChannel = [[args objectAtIndex:i] intValue];
        }
        else if([arg isEqualToString:@"s"]){
            serverName = [args objectAtIndex:i];
        }
        else if([arg isEqualToString:@"p"]){
            password = [args objectAtIndex:i];
        }
        else if([arg isEqualToString:@"L"]){
            deviceLabel = [args objectAtIndex:i];
        }
        else if([arg isEqualToString:@"r"]){
            remote = YES;
        }
        else if([arg isEqualToString:@"h"]){
            isHubPort = YES;
        }
    }
    
    
    if(logfile != nil){
        result = PhidgetLog_enable(PHIDGET_LOG_INFO, [logfile cStringUsingEncoding:NSASCIIStringEncoding]);
        if(result != EPHIDGET_OK){
  //          [PhidgetInfoBox error:result];
            errorOccurred = YES;
        }
    }
    if(deviceLabel != nil){
        result = Phidget_setDeviceLabel(phid, [deviceLabel cStringUsingEncoding:NSASCIIStringEncoding]);
        if(result != EPHIDGET_OK){
  //          [PhidgetInfoBox error:result];
            errorOccurred = YES;
        }
    }
    
    if(serverName != nil){
        remote = YES;
        result = Phidget_setServerName(phid, [serverName cStringUsingEncoding:NSASCIIStringEncoding]);
        if(result != EPHIDGET_OK){
  //          [PhidgetInfoBox error:result];
            errorOccurred = YES;
        }
        if(password != nil){
            result = PhidgetNet_setServerPassword([serverName cStringUsingEncoding:NSASCIIStringEncoding], [password cStringUsingEncoding:NSASCIIStringEncoding]);
            if(result != EPHIDGET_OK){
 //               [PhidgetInfoBox error:result];
                errorOccurred = YES;
            }
        }
    }
    
    result = Phidget_setChannel(phid, (int)deviceChannel);
    if(result != EPHIDGET_OK){
 //       [PhidgetInfoBox error:result];
        errorOccurred = YES;
    }
    
    result = Phidget_setDeviceSerialNumber(phid,serialNumber == 0 ? -1 : (int)serialNumber);
    if(result != EPHIDGET_OK){
  //      [PhidgetInfoBox error:result];
        errorOccurred = YES;
    }
    
    result = Phidget_setHubPort(phid, (int)hubPort);
    if(result != EPHIDGET_OK){
  //      [PhidgetInfoBox error:result];
        errorOccurred = YES;
    }
    
    result = Phidget_setIsHubPortDevice(phid, isHubPort);
    if(result != EPHIDGET_OK){
 //       [PhidgetInfoBox error:result];
        errorOccurred = YES;
    }
    
   
    if(remote){
        result = Phidget_setIsRemote(phid, 1); //force open to look for remote devices only
        if(result != EPHIDGET_OK){
 //           [PhidgetInfoBox error:result];
            errorOccurred = YES;
        }
        
        result = PhidgetNet_enableServerDiscovery(PHIDGETSERVER_DEVICEREMOTE);
        if(result != EPHIDGET_OK){
  //          [PhidgetInfoBox error:result];
            errorOccurred = YES;
        }
    }
    else{
        result = Phidget_setIsLocal(phid, 1);
        if(result != EPHIDGET_OK){
   //         [PhidgetInfoBox error:result];
            errorOccurred = YES;
        }
    }
    
    if(errorOccurred){
        NSModalResponse returnValue;
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:[NSString stringWithFormat:@"Invaid Command Line Argument\nUsage:\n %@ Flags[...]\n\nFlags:\n-n serialNumber: defaults to -1 (any serial number)\n\n-l logFile: enable logging to specified logFile\n\n-v port: defaults to 0\n\n-c deviceChannel: defaults to 0\n\n-h hubPort?: device is a hub port, defaults to 0\n\n-L deviceLabel, assign a label to the device\n\n-r remote, will autoconnect to available servers, no other configuration is required\n\n-s serverName\tuse only if a specific server is known, otherwise use -r for any server\n\n-p password\tomit for no password",[args objectAtIndex:0]]];
        [alert setAlertStyle:NSAlertStyleCritical];
        returnValue = [alert runModal];
        if(returnValue != NSAlertFirstButtonReturn){
            return;
        }
    }
    else{
        result = Phidget_open(phid);
        if(result != EPHIDGET_OK)
            ;
  //          [PhidgetInfoBox error:result];
        
    }
    
}

@end

