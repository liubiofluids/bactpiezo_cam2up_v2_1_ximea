//
//  CameraDisplay.h
//  bacttrack
//
//  Created by Bin Liu on 8/11/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <dc1394/dc1394.h>
#ifndef BRTNSS0
#define BRTNSS0 (1.0)
#endif

#ifndef EXPSR0
#define EXPSR0 (3000)
#endif

typedef struct camstats{
    bool flagframeupdated;
    bool flagframecaptured;
    bool flagfullscreen;
    bool flag_stopped=TRUE;
    bool flag_imgszupdted=FALSE;
    bool flag_capture;
    bool linkstatus=FALSE;
    bool flag_cam_stats=false;
    unsigned int exposure_time=EXPSR0;
    float brightness=BRTNSS0;
    NSString* sVendor;
    NSString* sModel=false;
} camstats;




extern dc1394_t * d;
extern dc1394camera_list_t * list;
extern dc1394error_t err;
extern dc1394camera_t **camera;

@interface CameraList : NSObject {
	unsigned int num_camera;

}

- (id) init ;

- (unsigned int) CameraNumber ;
@end
