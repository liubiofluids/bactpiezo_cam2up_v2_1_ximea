//
//  CameraListController.m
//
//  Created by Bin Liu on 8/9/11.
//  Copyright 2011 New York University. All rights reserved.
//
#import "CameraListController.h"

@implementation CameraListController

- (id)init
{
    if (self = [super init])
    {
		// Initialization code here
		linkstatus=FALSE;
		m_imgBuffer=[[Queue alloc ] init];
		m_bufferSize=100;
        m_img_buffer=NULL;
        m_track_width0=width;
        m_track_height0=height;
        flagTargetLocked=TRUE;
        m_graylevelmax=10.;
        flag_cam_stats=NO;
        memset(pflagcamstatus, 0, sizeof(bool)*NMAXCAM);
        memset(pflagcall, 0, sizeof(bool)*NMAXCAM);
        memset(pfrmnum, 0, sizeof(int)*NMAXCAM);
        memset(pcount, 0, sizeof(unsigned long int)*NMAXCAM);
        
        NSString* currPath=[[NSBundle mainBundle] bundlePath];
        NSString* ssfile = [currPath stringByAppendingFormat:@"/../stgserial.txt" ];
        FILE *infile=fopen([ssfile UTF8String ], "r");
        if(infile){
            int nit = 0;
            while (!feof(infile) && nit<3){
                fscanf(infile, "%d", pserial+nit++);
            }
            fclose(infile);
        }
        [icb_inverse enable];
        [iautocontrast enable];
        
        
	}
//	NSLog(@"piezo1: %d, %d", piezo01, m_stepper_1);
    return self;
}

- (void) awakeFromNib
{
	[cameraModel setTitleWithMnemonic: @"No camera!"];
    [cammodSwitch setEnabled: false];
	[self setPicture: CAMERA_OTHERS];
	int heightChange;
	NSRect panelframe = [mainWindow frame];

	heightChange = panelframe.size.height - 469;
	panelframe.origin.y += heightChange;
	panelframe.size.height -= heightChange;
    numcam=[m_camera_list CameraNumber];
    numcam_xi = [xi_camera_list CameraNumber];


    m_camid=0; //current camera being configured.
    numcam_tot=numcam+numcam_xi;
    
    if(numcam_tot>0){
        camera_info=new camstats [numcam_tot];
        exposure_time=new unsigned int [numcam_tot];
        m_brightness_multip=new float [numcam_tot];
        m_camera_type = new CameraType[numcam_tot];
        pview=new fullscreenWindow* [numcam_tot]();
        ppreviewContr=new QPreviewController* [numcam_tot]();
        pcurr_frame_time=new double [numcam_tot];
        pimg_buffer=new unsigned char* [numcam_tot]();
        pbuffer=new unsigned char* [numcam_tot ]();
        plock=new NSLock* [numcam_tot]();
        
        [brightnessSetValue setStringValue: [NSString stringWithFormat: @"%0.2f",.5*camera_info[m_camid].brightness]];
        [brightnessSetTrack setFloatValue: .5*camera_info[m_camid].brightness];
        [previewControlBox setHidden:FALSE];
        [stageControlBox setHidden:FALSE];
        [exposureSetValue setIntValue: camera_info[m_camid].exposure_time];
        [exposureSetTrack setIntValue: camera_info[m_camid].exposure_time];
        [exposureSetTrack setMaxValue: 100000.];
    }

	if(numcam){
		
		
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
        NSLog(@"vendor:%d", camera[m_camid]->vendor);
        [cammodSwitch setNumberOfVisibleItems:numcam];
 
 
        pcurr_frame=new dc1394video_frame_t* [numcam]();
        
        for(int i=0; i<numcam; i++){
            NSLog(@"Camera Model: %d", camera[i]);
            [cammodSwitch insertItemWithObjectValue:[NSString stringWithUTF8String: (camera[i]->model) ] atIndex:i];
            camera_info[i].exposure_time=exposure_time0;
            camera_info[i].brightness=m_brightness_multip0;
            camera_info[i].sVendor=[[NSString alloc] initWithUTF8String: (camera[i]->vendor) ]; //@"AVT";
            camera_info[i].sModel=[[NSString alloc] initWithUTF8String: (camera[i]->model) ]; //@"Pike F032B";
            if ([camera_info[i].sVendor compare: @"AVT"]==NSOrderedSame){
                NSLog(@"type0");
                m_camera_type[i]=PIKE_032B;
            }
            else if([camera_info[i].sVendor compare: @"Point Grey Research"]==NSOrderedSame) {
                NSLog(@"type1");
                m_camera_type[i]=POINTGREY;
            }
            else {
                 NSLog(@"type3");
                m_camera_type[i]=CAMERA_OTHERS;
            }
            if(i==0){
                pview[i]=viewWindow;
                ppreviewContr[i]=m_previewController;
                [ppreviewContr[i] setCameraID:i];
            }
            else{
                pview[i]=viewWindow_mult;
                ppreviewContr[i]=m_previewController_mult;
                [ppreviewContr[i] setCameraID:i];
            }
            NSLog(@"camera_type:%d, %d", i, m_camera_type[i]);
            plock[i]=[[NSLock alloc] init];
            if(i<NMAXCAM){
                pimgBuffer[i]=[[Queue alloc ] init];
            }
        }
        [cammodSwitch selectItemAtIndex:0];
        if (numcam>1){
            [cammodSwitch setEnabled: true];
        }

    
		[cameraModel setStringValue: camera_info[m_camid].sModel];
		[m_run_button setEnabled: YES];
        NSLog(@"vendor: %s", [camera_info[m_camid].sVendor UTF8String]);
		if ([camera_info[m_camid].sVendor compare: @"AVT"]==NSOrderedSame) {
			[cameraManuf setStringValue: @"Allied Vision Tech"];
			[self setPicture: PIKE_032B];
		}
        else if([camera_info[m_camid].sVendor compare: @"Point Grey Research"]==NSOrderedSame) {
            [cameraManuf setStringValue: @"Point Grey"];
            [self setPicture: POINTGREY];
        }
		heightChange = panelframe.size.height - 330;
		panelframe.origin.y += heightChange;
		panelframe.size.height -= heightChange;
		[mainWindow setMinSize:panelframe.size];
		[mainWindow setFrame:panelframe display:YES animate:NO];
		[mainWindow display];
		[pool release];
    }
    
    if (numcam_xi){
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [cammodSwitch setNumberOfVisibleItems:numcam_tot];
        HANDLE xiH;
        char modelName[32];
        
        pxiframe=new XI_IMG* [numcam_xi]();
        xiframe = new XI_IMG [numcam_xi]();
        
        for (DWORD i=0; i<numcam_xi; i++){
            
            memset(&xiframe[i], 0, sizeof(xiframe[i]));
            xiframe[i].size = sizeof(XI_IMG);
            pxiframe[i]=&xiframe[i];
            // Set the parameter to query the camera model name
            xiH = [xi_camera_list InitiateDevice:i];
            hxicamera[i]=xiH;
           // Get the camera model name
            
            XI_RETURN stat = xiGetParamString(xiH, XI_PRM_DEVICE_NAME, modelName, sizeof(modelName));
            if (stat == XI_OK) {
                NSLog(@"XIMEA Camera Model: %d, %s", numcam_tot, modelName);
                camera_info[i+numcam].sModel=[[NSString alloc] initWithUTF8String: modelName ]; //@"Pike F032B";
                [cammodSwitch insertItemWithObjectValue:[NSString stringWithUTF8String: modelName ] atIndex:i+numcam];
                camera_info[i+numcam].exposure_time=exposure_time0;
                camera_info[i+numcam].brightness=m_brightness_multip0;
                camera_info[i+numcam].sVendor=[[NSString alloc] initWithUTF8String: "XIMEA" ];
                if ([camera_info[i+numcam].sVendor compare: @"AVT"]==NSOrderedSame){
                    NSLog(@"type0");
                    m_camera_type[i+numcam]=PIKE_032B;
                }
                else if([camera_info[i+numcam].sVendor compare: @"Point Grey Research"]==NSOrderedSame) {
                    NSLog(@"type1");
                    m_camera_type[i+numcam]=POINTGREY;
                }
                else if([camera_info[i+numcam].sVendor compare: @"XIMEA"]==NSOrderedSame) {
                    NSLog(@"type2");
                    m_camera_type[i+numcam]=XIMEA;
                }
                else {
                    NSLog(@"type3");
                    m_camera_type[i+numcam]=CAMERA_OTHERS;
                }
                if(i+numcam==0){
                    pview[i]=viewWindow;
                    ppreviewContr[i]=m_previewController;
                    [ppreviewContr[i] setCameraID:i];
                }
                else{
                    pview[i+numcam]=viewWindow_mult;
                    ppreviewContr[i+numcam]=m_previewController_mult;
                    [ppreviewContr[i+numcam] setCameraID:i+numcam];
                }

            } else {
                NSLog(@"Get XIMEA Camera Model Failed!");
            }
        }
        [cammodSwitch selectItemAtIndex:0];
        if (numcam_tot>1){
            [cammodSwitch setEnabled: true];
        }
        plock[i+numcam]=[[NSLock alloc] init];
        pimgBuffer[i+numcam]=[[Queue alloc ] init];

        
        [cameraModel setStringValue: [NSString stringWithUTF8String: modelName]];
        [m_run_button setEnabled: YES];
        if ([camera_info[m_camid].sVendor compare: @"XIMEA"]==NSOrderedSame) {
            [cameraManuf setStringValue: @"XIMEA"];
            [self setPicture: XIMEA];
        }
        heightChange = panelframe.size.height - 330;
        panelframe.origin.y += heightChange;
        panelframe.size.height -= heightChange;
        [mainWindow setMinSize:panelframe.size];
        [mainWindow setFrame:panelframe display:YES animate:NO];
        [mainWindow display];
        [pool release];


    }
	m_lock = [[NSLock alloc] init];
    m_lock_video = [[NSLock alloc] init];
    m_lock_piezo = [[NSLock alloc] init];
	buffer_lock=[[NSLock alloc] init];
    stage_lock = [[NSLock alloc] init];
    trace_lock = [[NSLock alloc] init];
}

- (void) updateFrame:(NSTimer *) timer {
//	printf("%d\n", curr_frame);
//	int windowLevel;
	static bool fullscreenEnabled=NO;
	if (flagfullscreen & !fullscreenEnabled) {
		NSRect screenRect = [[NSScreen mainScreen] frame];
		
		m_oldRect=[pview[m_camid] frame];
//		NSLog(@"old: %f, %f, %f, %f", m_oldRect.origin.x, m_oldRect.origin.y, m_oldRect.size.width, m_oldRect.size.height);
		NSRect newRect;
		newRect.origin=NSMakePoint(0., 0.);//screenRect.origin;
		newRect.size.width=screenRect.size.width;
		newRect.size.height=screenRect.size.height+22;
		m_oldLevel=[viewWindow_mult level];
		[pview[m_camid] setLevel:CGShieldingWindowLevel()];
        [pview[m_camid] makeKeyAndOrderFront:self];//[viewWindow_mult makeKeyAndOrderFront:YES];
		[pview[m_camid] setMinSize: newRect.size];

		[pview[m_camid] setFrame:newRect display:YES animate:NO];
//		[pview[m_camid] setStyleMask:NSBorderlessWindowMask]; //firstresponder do not respond to keyboard after this command
		[pview[m_camid] setBackingType:NSBackingStoreBuffered];
/*		[pview[m_camid] display];
*/
		fullscreenEnabled=YES;
	}
	else if (!flagfullscreen & fullscreenEnabled)
	{
//		NSRect currRect=[viewWindow_mult frame];
//		NSLog(@"origin: %d, %f, %f,%f, %f", (int)viewWindow_mult, m_oldRect.origin.x, m_oldRect.origin.y, m_oldRect.size.width, m_oldRect.size.height);
//		[pview[m_camid] setLevel:m_oldLevel];
//		[pview[m_camid] makeKeyAndOrderFront:YES];
		[pview[m_camid] setMinSize: m_oldRect.size];
		[pview[m_camid] setFrame: m_oldRect display: YES animate: NO];
//		[pview[m_camid] setStyleMask: NSMiniaturizableWindowMask]; //firstresponder do not respond to keyboard after this command
		fullscreenEnabled=NO;
	}
	//[m_previewController update ];
    size_t numcam=[m_camera_list CameraNumber];
    size_t numcam_xi = [xi_camera_list CameraNumber];
    size_t numcam_tot = numcam+numcam_xi;
    for(    int i=0; i<numcam_tot; i++){
        [ppreviewContr[i] update];
    }
}

- (void) thread_capture {
	static int frm_num=0;
    //static
    NSDate *prevdate=[[NSDate alloc] init];
    flag_cam_stats=YES;
    unsigned int idcam=m_camid;
    camera_info[idcam].flag_cam_stats=true;
    pflagcamstatus[idcam]=YES;
    XI_IMG image;
    memset(&image, 0, sizeof(image));
    image.size = sizeof(XI_IMG);
    
    while(camera_info[idcam].flag_capture){//(flag_capture) {
//		printf("%d, %d\n", curr_frame, i++);
//		if(++frm_num==200)
        if(++pfrmnum[idcam]==200)
		{
//			elapsed_time = (douƒble)(clock()- start_time) / CLOCKS_PER_SEC;
//			start_time = clock();
            elapsed_time = [prevdate timeIntervalSinceNow];
            camera_frame_rate=-200/elapsed_time;
//			frm_num=0;
            pfrmnum[idcam]=0;
            NSDate *currdate=[NSDate date];
            prevdate=[currdate copy];
        }
		
		
		//err=dc1394_capture_dequeue(camera[idcam], DC1394_CAPTURE_POLICY_WAIT , &curr_frame);
        if (idcam<numcam){
            err=dc1394_capture_dequeue(camera[idcam], DC1394_CAPTURE_POLICY_WAIT , pcurr_frame+idcam);
        

            if (err!=DC1394_SUCCESS) {
                dc1394_log_error("unable to capture");
                if (camera){
                    dc1394_capture_stop(camera[idcam]);
                    dc1394_camera_free(camera[idcam]);
                }
                exit(1);
            }
		
		//dc1394_capture_enqueue(camera[idcam],curr_frame);
            dc1394_capture_enqueue(camera[idcam], pcurr_frame[idcam]);
        //unsigned long nbitsimg=curr_frame->size[0]*curr_frame->size[1]*sizeof(char);
            unsigned long nbitsimg=pcurr_frame[idcam]->size[0]*pcurr_frame[idcam]->size[1]*sizeof(char);
//        NSLog(@"frame size: %d, %d", curr_frame->size[0], curr_frame->size[1]);
            [m_lock_video lock];
		//memcpy(m_img_buffer, curr_frame->image, nbitsimg);
            memcpy(pimg_buffer[idcam], pcurr_frame[idcam]->image, nbitsimg);
        
            flagframecaptured=TRUE;
            [m_lock_video unlock];
            //curr_frame_time=[startdate timeIntervalSinceNow];
            pcurr_frame_time[idcam]=[startdate timeIntervalSinceNow];
            NSLog(@"time:: %d, %f", idcam, curr_frame_time);
        
            if (!flagtrack) {
                [m_lock lock];
                [plock[idcam] lock];
                /*memcpy(img_buffer, m_img_buffer, nbitsimg);*/
                memcpy(pbuffer[idcam], pimg_buffer[idcam], nbitsimg);
                flagframeupdated=TRUE;
                [m_lock unlock];
                [plock[idcam] unlock];
            }
        }
        else if (numcam_xi>0){
            NSLog(@"image mem: %d, %d",image, hxicamera[idcam-numcam]);
            XI_RETURN stat = xiGetImage(hxicamera[idcam-numcam], 5000, &xiframe[idcam-numcam]);
            unsigned long nbitsimg=xiframe[idcam-numcam].width*xiframe[idcam-numcam].height*sizeof(unsigned char);
            NSLog(@"image size: %d, %d", xiframe[idcam-numcam].width, xiframe[idcam-numcam].height);
            memcpy(pimg_buffer[idcam], (unsigned char*)xiframe[idcam-numcam].bp, nbitsimg);
            NSLog(@"image data: %d, %d", *(pimg_buffer[idcam]), *(pimg_buffer[idcam]+20));
            flagframecaptured=TRUE;
            [m_lock_video unlock];
            //curr_frame_time=[startdate timeIntervalSinceNow];
            pcurr_frame_time[idcam]=[startdate timeIntervalSinceNow];
            NSLog(@"time:: %d, %f", idcam, curr_frame_time);
            
            if (!flagtrack) {
                [m_lock lock];
                [plock[idcam] lock];
                /*memcpy(img_buffer, m_img_buffer, nbitsimg);*/
                memcpy(pbuffer[idcam], pimg_buffer[idcam], nbitsimg);
                flagframeupdated=TRUE;
                [m_lock unlock];
                [plock[idcam] unlock];
            }

        }
	}
    [prevdate release];
    if (numcam>idcam){
        NSLog(@"try end capt: %d, %d\n", camera[idcam], pflagcamstatus[idcam]);
    }

    camera_info[idcam].flag_cam_stats=false;
    flag_cam_stats=NO;
    pflagcamstatus[idcam]=NO;

/*    [m_lock lock];
    if (img_buffer){
        free(img_buffer);
        img_buffer=nil;
    }
    if (m_img_buffer){
        free(m_img_buffer);
        m_img_buffer=nil;
    }
    [m_lock unlock];
*/
    NSLog(@"try end capt: done, %d", pflagcamstatus[idcam]);
}


- (IBAction)LinkCamera:(id)sender {
	
//    static bool flag_call[3]={FALSE, FALSE, FALSE}; //3 camera max
//	printf("button: %d, %d", (int) flag_call, (int) [m_preview_switch isSelectedForSegment:0]);
//	NSLog(@"preview :%d ,%d , flag_call, [m_preview_switch isSelectedForSegment:1]\n");
	NSLog (@"serial: %d,%d,%d", [m_stepper_1 idAxis], [m_stepper_2 idAxis], [m_stepper_3 idAxis]);
    NSLog (@"view: %d, %d, %d", pview[m_camid], [m_preview_switch isSelectedForSegment:0], [m_preview_switch isSelectedForSegment:1]);
	if(!pflagcall[m_camid] & [m_preview_switch isSelectedForSegment:0]){
		[m_preview_switch setSelectedSegment: 0];
        [ppreviewContr[m_camid] setCameraID: m_camid]; // Assign camera id# to the view controller. 
        [ppreviewContr[m_camid] setBrightness:camera_info[m_camid].brightness];
        
		[pview[m_camid] orderFront: sender];
	ptrig_camera[m_camid] = [NSTimer scheduledTimerWithTimeInterval:1/29.97
													   target:self 
													 selector:@selector(updateFrame:) 
													 userInfo:nil 
													  repeats:YES];
        
        [[NSRunLoop mainRunLoop] addTimer:ptrig_camera[m_camid] forMode:NSRunLoopCommonModes];
		pflagcall[m_camid]=TRUE;
		
	}
	else if (pflagcall[m_camid] & [m_preview_switch isSelectedForSegment:1]) {
//		NSLog(@"preview off\n");
		[pview[m_camid] orderOut: sender];
		[ptrig_camera[m_camid] invalidate];
		ptrig_camera[m_camid]=nil;
		//[trig_camera release];
		[m_preview_switch setSelectedSegment: 1];
		pflagcall[m_camid]=FALSE;
		
	}
}

- (IBAction)SetCamera:(id)sender {

}

- (IBAction)CaptureVideo:(id)sender {
	
    dc1394video_mode_t video_mode;
	extern int grab_n_frames;
//	printf("grab_n_frames: %d\n", grab_n_frames);
    unsigned int idcam=m_camid;
    unsigned int x_left, y_top;
    unsigned int widthmax, heightmax;
    NSLog(@"Linked camera: %d, %d", idcam, camera_info[idcam].linkstatus);
 
	if (!camera_info[idcam].linkstatus) {
		[m_preview_switch setEnabled: YES];
		[m_track_switch setEnabled: YES];
		[m_control_swith setEnabled: YES];
        [m_text_resx setEnabled: NO];
        [m_text_resy setEnabled: NO];
		grab_n_frames=1000;
		if (!img_buffer) {
            NSLog(@"sizeimg: %d, %d", width, height);
            img_buffer=(unsigned char*)malloc(sizeof(char)*height*width);
            flag_imgszupdted=true; /* notify the rest of the program about the change (or initiate) of the image size */
		}
        if (!pbuffer[idcam]) {
            NSLog(@"sizeimg: %d, %d, %d", idcam, width, height);
            pbuffer[idcam]=(unsigned char*)malloc(sizeof(char)*height*width);
            flag_imgszupdted=true; /* notify the rest of the program about the change (or initiate) of the image size */
        }
        if (!m_img_buffer) {
            m_img_buffer = (unsigned char*)malloc(sizeof(char)*height*width);
        }
        if (!pimg_buffer[idcam]) {
            pimg_buffer[idcam]= (unsigned char*)malloc(sizeof(char)*height*width);
        }
        
        if (idcam<numcam){
            video_mode = DC1394_VIDEO_MODE_FORMAT7_0;
            err=dc1394_format7_get_max_image_size(camera[idcam], video_mode, &widthmax, &heightmax);
            NSLog(@"maxsize: %d, %d", widthmax, heightmax);
            dc1394_video_set_operation_mode(camera[idcam], DC1394_OPERATION_MODE_1394B);
            dc1394_video_set_iso_speed(camera[idcam], DC1394_ISO_SPEED_800);
            dc1394_video_set_mode(camera[idcam], video_mode);
            x_left=(widthmax-width)/2;
            y_top =(heightmax-height)/2;
            err = dc1394_format7_set_roi(camera[idcam], video_mode,
									 DC1394_COLOR_CODING_MONO8,
									 DC1394_USE_MAX_AVAIL, // use max packet size
									 x_left, y_top, // left, top
									 width, height);  // width, height
		
            err=dc1394_capture_setup(camera[idcam], 4, DC1394_CAPTURE_FLAGS_DEFAULT);
            //DC1394_ERR_CLN_RTN(err, dc1394_camera[m_camid]_free(camera[m_camid]), "Error capturing");
		
            /*-----------------------------------------------------------------------
             *  print allowed and used packet size
             *-----------------------------------------------------------------------*/
            err=dc1394_format7_get_packet_parameters(camera[idcam], video_mode, &min_bytes, &max_bytes);
		
            //DC1394_ERR_RTN(err,"Packet para inq error");
            printf( "camera reports allowed packet size from %d - %d bytes\n", min_bytes, max_bytes);
		
            err=dc1394_format7_get_packet_size(camera[idcam], video_mode, &actual_bytes);
            //DC1394_ERR_RTN(err,"dc1394_format7_get_packet_size error");
            printf( "camera[m_camid] reports actual packet size = %d bytes\n", actual_bytes);
		
            err=dc1394_format7_get_total_bytes(camera[idcam], video_mode, &total_bytes);
            //DC1394_ERR_RTN(err,"dc1394_query_format7_total_bytes error");
            printf( "camera reports total bytes per frame = %d bytes\n",total_bytes);
		
            /*-----------------------------------------------------------------------
             *  have the camera start sending us data
             *-----------------------------------------------------------------------*/
				
            err=dc1394_video_set_transmission(camera[idcam],DC1394_ON);
            if (err!=DC1394_SUCCESS) {
                dc1394_log_error("unable to start camera iso transmission");
                dc1394_capture_stop(camera[idcam]);
                NSLog(@"free camera");
                dc1394_camera_free(camera[idcam]);
                exit(1);
            }
            dc1394featureset_t features;
        
            err=dc1394_feature_get_all(camera[idcam],&features);
            if (err!=DC1394_SUCCESS) {
                dc1394_log_warning("Could not get feature set");
            }
            else {
                dc1394_feature_print_all(&features, stdout);
            }
        }
        else if (numcam_xi>0){
            XI_RETURN stat =  xiSetParamInt(hxicamera[idcam-numcam], XI_PRM_OFFSET_X, 0);  // Reset X offset
            stat = xiSetParamInt(hxicamera[idcam-numcam], XI_PRM_OFFSET_Y, 0);  // Reset Y offset
            stat = xiSetParamInt(hxicamera[idcam-numcam], XI_PRM_WIDTH, 0);     // Reset width
            stat = xiSetParamInt(hxicamera[idcam-numcam], XI_PRM_HEIGHT, 0);    // Reset height
            
            stat = xiSetParamInt(hxicamera[idcam-numcam], XI_PRM_IMAGE_DATA_FORMAT, XI_MONO8);
            
            stat = xiGetParamInt(hxicamera[idcam-numcam], XI_PRM_WIDTH, (int*)&widthmax);
            stat =  xiGetParamInt(hxicamera[idcam-numcam], XI_PRM_HEIGHT, (int*)&heightmax);
            NSLog(@"max image size: %d, %d", widthmax, heightmax);
            x_left=(widthmax-width)/2;
            y_top =(heightmax-height)/2;
            stat = xiSetParamInt(hxicamera[idcam-numcam], XI_PRM_WIDTH, (int)width);
            stat = xiSetParamInt(hxicamera[idcam-numcam], XI_PRM_HEIGHT, (int)height);
            stat = xiSetParamInt(hxicamera[idcam-numcam], XI_PRM_OFFSET_X, (int)x_left);
            stat = xiSetParamInt(hxicamera[idcam-numcam], XI_PRM_OFFSET_Y, (int)y_top);
            stat = xiStartAcquisition(hxicamera[idcam-numcam]);
        }
        
        unsigned int exptime;
        dc1394bool_t isfeature;
        
 
        
        
        switch (m_camera_type[idcam]){
            case POINTGREY: {
                err=dc1394_feature_set_mode(camera[idcam], DC1394_FEATURE_FRAME_RATE, DC1394_FEATURE_MODE_MANUAL);
                err=dc1394_feature_set_mode(camera[idcam], DC1394_FEATURE_SHUTTER, DC1394_FEATURE_MODE_MANUAL);
                err=dc1394_feature_set_mode(camera[idcam], DC1394_FEATURE_EXPOSURE, DC1394_FEATURE_MODE_MANUAL);
                float currframerate=1000000./(camera_info[idcam].exposure_time+40);
                err=dc1394_feature_set_absolute_value(camera[idcam], DC1394_FEATURE_FRAME_RATE, currframerate);
                break;
            }
            case PIKE_032B: {
                        err=dc1394_feature_set_value(camera[idcam], DC1394_FEATURE_SHUTTER, camera_info[idcam].exposure_time/10);
                break;
            }
            case XIMEA: {
                XI_RETURN stat = xiSetParamInt(hxicamera[m_camid-numcam], XI_PRM_EXPOSURE, camera_info[m_camid].exposure_time);
                
                break;
            }
            default: {
                err=dc1394_feature_set_absolute_value(camera[idcam], DC1394_FEATURE_SHUTTER, camera_info[idcam].exposure_time/1000000.);
                break;
            }
        }

        
  /*      dc1394_feature_is_switchable(camera[idcam], DC1394_FEATURE_FRAME_RATE, &isfeature);
        dc1394_feature_get_value(camera[idcam], DC1394_FEATURE_FRAME_RATE, &exptime);
        NSLog(@"exptime:  %d, %d, %d", exptime, camera_info[idcam].exposure_time, isfeature);
   */

/*        dc1394_feature_get_value(camera[idcam], DC1394_FEATURE_SHUTTER, &exptime);
        NSLog(@"exptime: %d", exptime);
*/
        /*-----------------------------------------------------------------------
		 *  capture 10 frames and measure the time for this operation
		 *-----------------------------------------------------------------------*/
		
        if(idcam<numcam){
            dc1394_get_image_size_from_video_mode(camera[idcam], DC1394_VIDEO_MODE_FORMAT7_0, &width, &height);
        }
        else if(numcam_xi>0){
            XI_RETURN stat = xiGetParamInt(hxicamera[idcam-numcam], XI_PRM_WIDTH, (int*)&width);
            stat =  xiGetParamInt(hxicamera[idcam-numcam], XI_PRM_HEIGHT, (int*)&height);
        }
        camera_info[idcam].flag_capture=true;
//      flag_capture=TRUE;
        [NSThread detachNewThreadSelector: @selector(thread_capture) toTarget:self withObject:nil];
		
		/*-----------------------------------------------------------------------
		 *  stop data transmission
		 *-----------------------------------------------------------------------*/
		
		/*-----------------------------------------------------------------------
		 *  save last image as Part.pgm
		 *-----------------------------------------------------------------------*/
		
		
		/*-----------------------------------------------------------------------
		 *  close camera, cleanup
		 *-----------------------------------------------------------------------*/
		camera_info[idcam].linkstatus=TRUE;
        linkstatus=TRUE;
		[m_run_button setTitle: @"Stop"];
        
        NSLog(@"free: %d", width);

	}
	else { 
//		printf("frame: %d, %d\n", img_buffer, i);
		camera_info[idcam].flag_capture=FALSE;
//        flag_capture=FALSE;
        if (idcam<numcam){
             NSLog(@"stop1: %ld, %d", camera[idcam], camera_info[idcam].flag_cam_stats);
        }
        
        while(camera_info[idcam].flag_cam_stats){
            if(idcam<numcam){
            NSLog(@"%ld, %d", camera[idcam], camera_info[idcam].flag_cam_stats);
            }
            usleep(1000);
        }
        NSLog(@"img_buffer: %d", img_buffer);
        unsigned char* tmp_ptr;
        if (img_buffer){
            tmp_ptr=img_buffer;
            img_buffer=nil;
            sleep(1);
            NSLog(@"free: img_buffer, %d", tmp_ptr);
            free(tmp_ptr); //free the address after defining it to be nil
        }
        if (pbuffer[idcam]){
            tmp_ptr=pbuffer[idcam];
            pbuffer[idcam]=nil;
            sleep(1);
            NSLog(@"free: img_buffer, %d", tmp_ptr);
            free(tmp_ptr); //free the address after defining it to be nil
        }
        if (m_img_buffer){
            tmp_ptr=m_img_buffer;
            m_img_buffer=nil;
            sleep(1);
            NSLog(@"free: m_img_buffer, %d", tmp_ptr);
            free(tmp_ptr);
        }
        if (pimg_buffer[idcam]){
            tmp_ptr=pimg_buffer[idcam];
            pimg_buffer[idcam]=nil;
            sleep(1);
            NSLog(@"free: m_img_buffer, %d", tmp_ptr);
            free(tmp_ptr);
        }

  //      NSLog(@"stop2: %ld", camera[m_camid]);
		[m_preview_switch setEnabled: NO];
  //      NSLog(@"stop3: %ld", camera[m_camid]);
		[m_track_switch setEnabled: NO];
		[m_control_swith setEnabled: NO];
        [m_text_resx setEnabled: YES];
        [m_text_resy setEnabled: YES];
		//[trig_camera release];
  //                      NSLog(@"stop4: %ld", camera[m_camid]);
        if (m_camid<numcam){
            dc1394_capture_stop(camera[m_camid]);
            NSLog(@"stop5: %ld", camera[m_camid]);
            dc1394_video_set_transmission(camera[m_camid], DC1394_OFF);
        }
        else if (numcam_xi>0){
            XI_RETURN stat = xiStopAcquisition(hxicamera[m_camid-numcam]);
 //           stat = xiCloseDevice(hxicamera[m_camid-numcam]);
        }
		//DC1394_ERR_RTN(err,"couldn't stop the camera?");
        
		grab_n_frames=2000;
		[m_run_button setTitle: @"Run"];
		camera_info[idcam].linkstatus=FALSE;
        linkstatus=FALSE;
	}
}


- (void) thread_track {
	
//	NSLog(@"flagtrack2: %d, %s", flagtrack, CfilenameFormat);
//    NSLog(@"trackwin: %d, %d", target_x, target_y );
	double levelavg;
    CvPoint tracexy;
    static long long counter=0;
    static double trace_x0=.5*width;
    static double trace_y0=.5*height;
    static double trace_z0=0;
    static double piezoctr=5.;
    static double harm_freq0=0.5*2*3.1415926; // customize frequency, (1 full cycle), unit Hz
    static double harm_amp_min=1, harm_amp_max=3; // customize amplitude,
    // 1/2 of amplitude value;  /unit V, 1 V= 5 micron zzz
    
    
    
    double voltdrift, apiezo;
    double piezoctr0=5.;
    double time_seconds, time_seconds0;
    double harm_amp;
    double harm_freq;
    unsigned int idcam=m_camid;
    while (flagtrack) {
		if(flagframecaptured){ 
//            NSLog(@"lock: %d\n", m_lock);
            
            [m_lock_video lock];
            flagframecaptured=FALSE;
            [m_lock_video unlock];
			
            
            [m_lock_video  lock];
            m_imgraw = [m_imgtoolbox Array2IplImageGray:pimg_buffer[idcam] width: width height: height];
//            m_imgraw = cvLoadImage("sample.jpg", CV_LOAD_IMAGE_GRAYSCALE);
            [m_lock_video unlock];
            IplImage* imgobject = cvCreateImage( cvSize( width, height ), m_imgraw->depth, m_imgraw->nChannels );
            cvCopy(m_imgraw, imgobject, NULL);
            NSCvImage* nsimgobject=[[NSCvImage alloc] initImage:imgobject timeInstance: pcurr_frame_time[idcam]];
            
            [buffer_lock lock];
//			if ([m_imgBuffer size]==m_bufferSize) {
            if ([pimgBuffer[idcam] size]==m_bufferSize) {
                [buffer_lock unlock];
                cvReleaseImage(&imgobject);
                cvReleaseImage(&m_imgraw);
                [nsimgobject release];
                continue;
                
			}
			else{
                
//				[m_imgBuffer push: nsimgobject];
                NSLog(@"pushbuffer: %d, %d", idcam, nsimgobject);
                [pimgBuffer[idcam] push: nsimgobject];
//                NSLog(@"bufferpoptest: %d", [pimgBuffer[idcam] pop]);
			}
            [buffer_lock unlock];
  //          NSLog(@"ROI: %d, %d\n", m_track_width, m_track_height);
            
  /*          [stage_lock lock];
            if(flagauto && !flag_stopped)
            {
                cvReleaseImage(&m_imgraw);
                [stage_lock unlock];
                continue; 
            }
            [stage_lock unlock];
   */
 
            CvRect rectROI=[m_imgtoolbox getcvRect:(int)floor(trace_x+.5) CY:(int)floor(trace_y+.5) ROIwidth:m_track_width ROIheight:m_track_height Imgwidth:width Imgheight:height];
            CvRect minRect;
    //        NSLog(@"ROI: %d, %d, %d, %d, %d, %d\n", rectROI.x, rectROI.y, rectROI.width, rectROI.height, width, height);
            cvSetImageROI(m_imgraw, rectROI);
            
            IplImage* imgROI=cvCreateImage(cvSize(rectROI.width, rectROI.height), m_imgraw->depth, m_imgraw->nChannels );

            cvCopy(m_imgraw, imgROI, NULL);

            IplImage* imgbw;
            tracexy.x=-1;
            int lcount=0;
    
 //           cvNot(imgROI, imgROI); //invert the image for fluorescence tracking
            
            if(m_blur>1.01){
                imgbw=[m_imgtoolbox Img2BW:[m_imgtoolbox ImgBlur: imgROI: m_blur] :m_threshold: 255];
            }
            else{
                imgbw=[m_imgtoolbox Img2BW:imgROI :m_threshold: 255];

            }


            m_graylevel=[m_imgtoolbox TrackCloseHole:imgbw: imgROI : m_areamin : m_areamax : &tracexy: &minRect: &m_weightedArea: m_geom: pcurr_frame_time[idcam]: m_threshold];

            if (tracexy.x==-1){
                if (!flag_tracelocked) {
                    trace_x=trace_x0;
                    trace_y=trace_y0;
                    m_track_width=2*m_track_width1;
                    m_track_height=2*m_track_height1;
                }
            }
            else{
                
                trace_x=(float)(tracexy.x+rectROI.x);
                trace_y=(float)(tracexy.y+rectROI.y);
                if (flag_tracelocked) {
                    m_track_width=m_track_width1;
                    m_track_height=m_track_height1;
                    
                }
            }

            
            //NSLog(@"rec: %lf, %d, %lf, %d", trace_x, rectROI.x, trace_x0, tracexy.x);
            if ([iautocontrast state] == NSOnState){
                double imgmin, imgmax;
                CvPoint locmin, locmax;
                cvMinMaxLoc(m_imgraw, &imgmin, &imgmax, &locmin, &locmax);
                cvRectangle(m_imgraw, cvPoint(minRect.x, minRect.y), cvPoint(minRect.x+minRect.width, minRect.y+minRect.height), cvScalar(imgmax, imgmax, imgmax, imgmax), 1, 8, 0);
            }
            else{
                cvRectangle(m_imgraw, cvPoint(minRect.x, minRect.y), cvPoint(minRect.x+minRect.width, minRect.y+minRect.height), cvScalar(255,255,255,255), 1, 8, 0);
            }
            //NSLog(@"rec: %lf, %d, %lf, %d", trace_x, rectROI.x, trace_x0, tracexy.x);
            NSLog(@"pos x: %f, y: %f", unit_xlen*(trace_x0-trace_x), trace_x0-trace_x);
            if (flagauto) {
                int change_x=(int)((unit_xlen*width/width0)*(trace_x0-trace_x));
                int change_y=(int)((unit_xlen*height/height0)*(trace_y0-trace_y));
                int change_z;
                float change_piezo;
                
                [piezo_lock lock];
                apiezo=actual_piezo;
                [piezo_lock unlock];
                
                if (m_graylevel>0.5 && m_graylevel<1.5 && !flag_focus){
                //    change_z=(int)((.71-m_graylevel)/0.0091);
                    
                    change_piezo=(m_dark1-m_graylevel)*slp_piezo;
                    m_graylevelmax=10.;
                
                    
                    [stage_lock lock];
                    target_x=actual_x-change_x; //minus for upright
                    target_y=actual_y-change_y;
                    [stage_lock unlock];
                    
                    if([piezo01 MonitorStatus]){
                        
                        time_seconds=time_seconds0-[startdate timeIntervalSinceNow]; //for harmonic test
                        NSLog(@"timetest: %f", time_seconds);
                        [m_lock_piezo lock];
                        //voltdrift=[piezo01 getDrift];
                        //target_piezo=piezoctr-.5*sin(2.*3.1415926*1.*time_seconds); flag_tracelocked=TRUE;
//for harmonic test
                        target_piezo=actual_piezo+change_piezo*.8;
                        [m_lock_piezo unlock];
                    }
                    else{ //open loop
                        [m_lock_piezo lock];
                        target_piezo=target_piezo+change_piezo;
                        //target_piezo=actual_piezo+change_piezo;
                        [m_lock_piezo unlock];
                    }
 
                }
                else if (m_graylevel>m_dark2 && m_graylevel<m_dark3 && flag_focus){
                    
                    
                    if(!flag_tracelocked){
                        flag_tracelocked=TRUE;
                    }
                    
                    
                    //target_piezo=piezoctr-0.8*sin((counter-2.)*0.01*2*3.1415926);
                    //target_piezo=actual_piezo-voltdrift;
   /*                 time_seconds=time_seconds0-[startdate timeIntervalSinceNow]-scandelay;
                    harm_amp=harm_amp_min+(harm_amp_max-harm_amp_min)*time_seconds;
                    harm_amp=harm_amp>harm_amp_max? harm_amp_max:harm_amp;
                    harm_freq=harm_freq0/harm_amp;
   */
                    //                 [m_lock_piezo lock];
                    //voltdrift=[piezo01 getDrift];
   /*                 NSLog(@"targetpiezo: %f", target_piezo);
                    target_piezo=piezoctr-harm_amp*sin(harm_freq*time_seconds); 
   */
                    //[m_lock_piezo unlock];
                    NSLog(@"targetpiezo: %f", target_piezo);
   
                    [stage_lock lock];
                    target_x=actual_x-change_x; //minus for upright
                    target_y=actual_y-change_y;
                    [stage_lock unlock];
 
                    flag_focus=FALSE;
                    counter=0;
                    usleep(10000);
                }
                else {
                    if(!flag_focus){
                        flag_focus=TRUE;
                        piezoctr=(target_piezo>9.0? 9.: target_piezo) ;
                        piezoctr=(piezoctr>1.? piezoctr: 1.);
                        time_seconds0=[startdate timeIntervalSinceNow];
                    }
                    
                    if(counter>1000000){
                        counter=0;
                    }
                    else if(counter>200 && flag_tracelocked){
                        flag_tracelocked=FALSE;
                        piezoctr=piezoctr0;
                    }
                    
                    time_seconds=time_seconds0-[startdate timeIntervalSinceNow];
                    harm_amp=harm_amp_min+fabs(harm_amp_max-harm_amp_min)*time_seconds;
                    harm_amp=harm_amp>harm_amp_max? harm_amp_max:harm_amp;
                    harm_freq=harm_freq0/harm_amp;
                    [m_lock_piezo lock];
                    target_piezo=piezoctr-harm_amp*sin(harm_freq*time_seconds); //for harmonic test
                    ++counter;
                    [m_lock_piezo unlock];
       /*             if (m_graylevel<0.75 && m_weightedArea>64){
                        [stage_lock lock];
                        target_x=actual_x+change_x;
                        target_y=actual_y+change_y;
                        [stage_lock unlock];
                    }        
        */
        /*            if (flag_tracelocked && trace_x>0){
                        [stage_lock lock];
                        target_x=actual_x-change_x;
                        target_y=actual_y-change_y;
                        [stage_lock unlock];
                    }
        */
                }
  //              NSLog(@"change x, y: %d, %d, %d, %lld, %lld, %lld, %lld, %lld, Z: %f, %f, drift: %f, flagfocus: %d", change_x, change_y, change_z, target_x, target_y, target_z, actual_x, actual_y, apiezo, target_piezo, voltdrift, flag_focus);
                
            }
            else{
                [m_lock_piezo lock];
                target_piezo=[piezo01 getPanelVolt];
                NSLog(@"target_panel: %f", target_piezo);
                [m_lock_piezo unlock];
            }
            NSLog(@"level: %f, %f, %f, %f, %f", m_graylevel, m_weightedArea, thrshld, trace_x, trace_y);
            
            cvResetImageROI(m_imgraw);
            
            [m_lock lock];
            memcpy(img_buffer, m_imgraw->imageData, width*height*sizeof(char));
            memcpy(pbuffer[idcam], m_imgraw->imageData, width*height*sizeof(char));
            flagframeupdated=TRUE;
            [m_lock unlock];
            
            cvReleaseImage(&imgROI);
            cvReleaseImage(&imgbw);
			cvReleaseImage(&m_imgraw);
            
		}
		else {
            usleep (2000);
		}
	}
 
}

- (void) thread_record {
	static int n=0;
    NSLog(@"record start :%d \n", flagrecorder);
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//    NSLog(@"imgname: %d", imgName);
//    NSLog(@"imgname: %s", [imgName UTF8String]);
	const char* CfilenameFormat=[imgName UTF8String];
	char Cfilename[100];
    char CInit[NMAXCAM] = {'f', 'g', 'h'};
    double frame_time;
    double frame_time0=0;
    float saveinter=1./(fabs(saverate)+1E-16);
    if(!startdate){
        startdate=[[NSDate alloc] init];
    }
    unsigned int idcam=m_camid;
//	NSLog(@"flagtrack2: %d, %s, %d", flagtrack, CfilenameFormat, m_imgBuffer);
	while(flagtrack) {
		
			
			[buffer_lock lock];
	//		NSLog(@"img: %d\n", [m_imgBuffer pop]);
//        NSCvImage* nsimgobject = [m_imgBuffer pop];
        NSCvImage* nsimgobject;
        nsimgobject=[pimgBuffer[idcam] pop];
        NSLog(@"pop: %d", nsimgobject);
        if (nsimgobject){
            m_imgsav=[nsimgobject getImage];
        
        }
        

/*        if (m_imgsav){
            
        m_test=cvCreateImage(cvSize(m_imgsav->width, m_imgsav->height), m_imgsav->depth, m_imgsav->nChannels);
        
        cv::Mat src=cv::cvarrToMat(m_imgsav); cv::Mat dst=cv::cvarrToMat(m_test);
        cv::GaussianBlur (src, dst, cv::Size(21, 21), 0, 0);

        }*/
        
        frame_time = [nsimgobject getTime];
    //   m_imgsav=[m_imgBuffer pop];
			[buffer_lock unlock];
		NSLog(@"record: %d, %d", flagrecorder, m_imgsav);
        if(flagrecorder && m_imgsav && (flag_tracelocked || flagcalibr)){
			sprintf(Cfilename, CfilenameFormat, n);
            NSLog(@"%s, %d, %d, %f", Cfilename, m_imgsav, m_imgsav->imageData, frame_time);
            if (flag_tracelocked || flagcalibr){ //(!flagcalibr) {
                if (saverate<1E-16) {
                    cvSaveImage(Cfilename, m_imgsav);
                }
                else if (frame_time0-frame_time>saveinter){
                    cvSaveImage(Cfilename, m_imgsav);
                }
            }
            if (saverate<1E-16 || frame_time0-frame_time>saveinter){
                
                xcrd[n]=target_x;//trace_x;
                ycrd[n]=target_y;//trace_y;
                zcrd[n]=target_z; //trace_z;
                zpiezo[n]=actual_piezo;
                [m_lock_piezo lock];
                vpiezo[n]=target_piezo;
                [m_lock_piezo unlock];
                time_i[n]=frame_time;
                area[n]=m_weightedArea;
                level[n]=m_graylevel;
                n++;
                data_counter++;
                frame_time0=frame_time;
            }
            
		}
        
        cvReleaseImage(&m_imgsav);
        cvReleaseImage(&m_test);
        [nsimgobject release];
		sleep(0.001);

	}
	
	[pool release];
	
}


- (IBAction)TrackVideo:(id)sender {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	imgName=[[NSString alloc] initWithString:[m_text_imgname stringValue]];
	imgPath=[[NSString alloc] initWithString:[m_text_imgpath stringValue]];
//	NSString *fileName = [fileNameTextField stringValue];
//	NSString *username = [usernameTextField stringValue];
//	NSString *fileName = [fileName stringByAppendingPathExtension:@"txt"];    // Append ".txt" to filename
    NSString *logName = [[imgPath stringByExpandingTildeInPath] stringByAppendingFormat:@"/data_cord.txt"];
    imgName = [[[imgPath stringByExpandingTildeInPath] stringByAppendingFormat:@"/%03d/", indx_folder ] stringByAppendingPathComponent:imgName];    // Expand '~' to user's home directory, and then append filename

//	[username writeToFile: imgPath atomically:YES];
//	imgName=[imgPath stringByAppendingString: imgName];
//	NSLog(@"flagtrack: %d, %d, %s\n", flagtrack, imgName,[imgName UTF8String]);
	if (!flagtrack & [m_track_switch isSelectedForSegment:0] ) {
        NSFileManager *fileManager= [NSFileManager defaultManager]; 
        if(flagrecorder){
            if(![fileManager fileExistsAtPath:[[imgPath stringByExpandingTildeInPath] stringByAppendingFormat:@"/%03d/", indx_folder ]] )
                if(![fileManager createDirectoryAtPath:[[imgPath stringByExpandingTildeInPath] stringByAppendingFormat:@"/%03d/", indx_folder]
                           withIntermediateDirectories:YES attributes:nil error:NULL])
                    NSLog(@"Error: Create folder failed %@", [[imgPath stringByExpandingTildeInPath] stringByAppendingFormat:@"/%03d/", indx_folder]);
            
            indx_folder++;
        }
        m_track_width1=[m_text_track_width intValue];
        m_track_height1=[m_text_track_height intValue];
        m_track_width=m_track_width1;
        m_track_height=m_track_height1;
        m_threshold=[m_text_threshold floatValue];
        m_areamax=[m_text_areamax intValue];
        m_areamin=[m_text_areamin intValue];
        m_dark1=[m_text_dark1 floatValue];
        m_dark2=[m_text_dark2 floatValue];
        m_dark3=[m_text_dark3 floatValue];
        m_geom=[m_text_geom floatValue];
        m_blur=[m_text_blur floatValue];
        
        flagtrack = TRUE;
		[NSThread detachNewThreadSelector: @selector(thread_track) toTarget:self withObject:nil];
 //       NSLog(@"record: %s \n", [imgName UTF8String]);
		[NSThread detachNewThreadSelector: @selector(thread_record) toTarget:self withObject:imgName];
		[m_track_switch setSelectedSegment: 0];
	}
	else if (flagtrack & [m_track_switch isSelectedForSegment:1]) { 
		flagtrack = FALSE;
		[m_track_switch setSelectedSegment: 1];
        
		FILE *outfile=fopen([logName UTF8String], "w");
   //     NSLog(@"%s, %d, %d\n", [logName UTF8String], outfile, time_i[0]);
//        NSLog(@"save: %d", (int) data_counter);
		for (int i=0; i<data_counter; i++){
			fprintf(outfile, "%lf %d %d %d %f %f %f %f\n", time_i[i], (int)xcrd[i], (int)ycrd[i], (int)zcrd[i], zpiezo[i], vpiezo[i], area[i], level[i]);
		}
		fclose(outfile);

	}
	[pool release];
    
}

- (IBAction)SetTracker:(id)sender {

}

- (void)setPicture:(int)camera_id
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *imgPath;
	
	switch(camera_id)
	{
		case PIKE_032B:
			imgPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"pike032" ofType:@"icns"];
			break;
        case POINTGREY:
            imgPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"PointGrey" ofType:@"icns"];
            break;
        case XIMEA:
            imgPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"ximea" ofType:@"icns"];
            break;
/*		case PHIDID_BIPOLAR_STEPPER_1MOTOR:
			imgPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"1063_0" ofType:@"icns"];
			break;
		case PHIDID_UNIPOLAR_STEPPER_4MOTOR:
			imgPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"1062_0" ofType:@"icns"];
			break;
*/		default:
			imgPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"help" ofType:@"icns"];
			NSLog(@"set picture!: %d\n", camera_id); 
//			imgPath = nil;
			break;
	}
	
	NSImage *img = [[NSImage alloc]  initByReferencingFile:imgPath];
	
	//otherwise the images are just painted over each other - and the transparency causes trouble
	[pictureBox setImage:nil];
	[pictureBox display];
	if(imgPath!=nil)
		[NSApp setApplicationIconImage: img];
	NSLog(@"imgpath: %d", imgPath);
	[pictureBox setImage:img];
	[pictureBox display];
	
	[pool release];
    NSLog(@"imgpath: %d", imgPath);
}

- (IBAction)setExposure: (id)sender {
//	NSLog(@"set exposure\n");
	unsigned int expsr=[sender intValue];
    exposure_time[m_camid]= expsr;
    camera_info[m_camid].exposure_time =  expsr;
	[m_lock_video lock];
    switch (m_camera_type[m_camid]){
        case POINTGREY: {
            float currframerate=1000000./(camera_info[m_camid].exposure_time+40);
            err=dc1394_feature_set_absolute_value(camera[m_camid], DC1394_FEATURE_FRAME_RATE, currframerate);
            err=dc1394_feature_set_absolute_value(camera[m_camid], DC1394_FEATURE_SHUTTER, camera_info[m_camid].exposure_time/1000000.);
            break;
        }
        case PIKE_032B: {
            err=dc1394_feature_set_value(camera[m_camid], DC1394_FEATURE_SHUTTER, camera_info[m_camid].exposure_time/10);
            break;
        }
        case XIMEA: {
            XI_RETURN stat = xiSetParamInt(hxicamera[m_camid-numcam], XI_PRM_EXPOSURE, camera_info[m_camid].exposure_time);
            break;
        }
        default: {
            err=dc1394_feature_set_absolute_value(camera[m_camid], DC1394_FEATURE_SHUTTER, camera_info[m_camid].exposure_time/1000000.);
            break;
        }
    }

	[m_lock_video unlock];
	[exposureSetValue setIntValue: expsr];
	[exposureSetTrack setIntValue: expsr];
}

- (IBAction)setBrightness: (id)sender {
//	NSLog(@"set exposure\n");
	float brght=[sender floatValue];
    camera_info[m_camid].brightness=2.*brght;
	[brightnessSetValue setStringValue: [NSString stringWithFormat: @"%0.2f",brght]];
	[brightnessSetTrack setFloatValue:brght=brght];
	m_brightness_multip[m_camid]=2.*brght;
    [ppreviewContr[m_camid] setBrightness:2.*brght];
}

- (IBAction)autocontrastSelect: (id)sender {
    if ([iautocontrast state] == NSOnState){
        [brightnessSetTrack setEnabled:NO];
        [brightnessSetValue setEnabled:NO];
      }
    else{

        NSLog(@"contrast:%d", [iautocontrast state] == NSOnState);
        [brightnessSetTrack setEnabled:YES];
        [brightnessSetValue setEnabled:YES];
    }
}

- (IBAction)invertSelect: (id)sender {
    NSLog(@"icbstate: %d", [icb_inverse state]);
    if ([icb_inverse state] == NSOnState){
        [icb_inverse setState:NSOnState];
    }
    else{
        [icb_inverse setState:NSOnState];
    }
}


- (IBAction)recorderSelected: (id)sender {
	//[recorderSwitch selectedCell];
	NSLog(@"selected: %d", [sender intValue]);
	flagrecorder=YES;
}

- (IBAction)recorderDeselected: (id)sender {
	//[recorderSwitch selectedCell];
	NSLog(@"deselected: %d", [sender intValue]);
	flagrecorder=NO;
}

- (IBAction)manualSelected:(id)sender{
    flagauto=NO; 
}

- (IBAction)manualDeselected:(id)sender{
    [m_lock_piezo lock];
    target_piezo=[piezo01 getPanelVolt];
    [m_lock_piezo unlock];
    flagauto=YES;
}

- (IBAction)calibrSelected: (id)sender{
    flagcalibr=YES;
}
- (IBAction)calibrDeselected: (id)sender{
    flagcalibr=NO;
}

- (IBAction)selectCamera:(id)sender{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    m_camid=[cammodSwitch indexOfSelectedItem];
    NSLog(@"m_camid: %d", m_camid);
     NSLog(@"m_camid bright: %f", camera_info[m_camid].brightness);
    NSLog(@"camera_info[m_camid]: %s, %d", [camera_info[m_camid].sVendor cStringUsingEncoding:NSUTF8StringEncoding] ,m_camera_type[m_camid]);
    switch (m_camera_type[m_camid]){
        case PIKE_032B:
            [cameraManuf setStringValue: @"Allied Vision Tech"];

            break;
        default:
            [cameraManuf setStringValue: camera_info[m_camid].sVendor ];
  
            break;
            
    }
    [self setPicture: m_camera_type[m_camid]];

    
    [brightnessSetValue setStringValue: [NSString stringWithFormat: @"%0.2f",.5*camera_info[m_camid].brightness]];
    [brightnessSetTrack setFloatValue: .5*camera_info[m_camid].brightness];
    [previewControlBox setHidden:FALSE];
    [stageControlBox setHidden:FALSE];
    [exposureSetValue setIntValue: camera_info[m_camid].exposure_time];
    [exposureSetTrack setIntValue: camera_info[m_camid].exposure_time];
    [ppreviewContr[m_camid] setBrightness:camera_info[m_camid].brightness];
    [m_preview_switch setSelectedSegment:!pflagcall[m_camid]];
    if(camera_info[m_camid].linkstatus==TRUE){
        [m_run_button setTitle: @"Stop"];
        [m_preview_switch setEnabled:TRUE];
    }
    else{
        [m_run_button setTitle: @"Run"];
    }
    [pool release];
}
@end
