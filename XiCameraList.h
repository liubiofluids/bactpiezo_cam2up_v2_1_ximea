//
//  XiCameraList.h
//  bacttrack
//
//  Created by Bin Liu on 10/10/23.
//
//

#import <Cocoa/Cocoa.h>
#include <m3api/xiApi.h>

extern HANDLE* hxicamera;

#define HandleResult(res,place) if (res!=XI_OK) {printf("Error after %s (%d)\n",place,res);goto xifinish;}



@interface XiCameraList : NSObject {
    DWORD num_camera;
    HANDLE* hxicam;
}

- (id) init ;

- (DWORD) CameraNumber ;

- (HANDLE) InitiateDevice: (DWORD) deviceIdx;

@end

