//
//  XiCameraList.m
//  bacttrack
//
//  Created by Bin Liu on 10/10/23.
//
//

#import "XiCameraList.h"

@implementation XiCameraList

- (id)init{
    if (self = [super init]) {
        // Initialization code here.
        printf("initiating!\n");
        
        HANDLE xiH = NULL;
        num_camera=0;
        XI_RETURN stat=xiGetNumberDevices(&num_camera);
        if (stat==XI_OK){
             NSLog(@"numcam: %d", num_camera);
            if(num_camera>0){
                hxicamera = new HANDLE[num_camera];
                NSLog(@"hicam:%d", hxicam);
                stat = xiOpenDevice(0, &xiH);
                HandleResult(stat, "xiOpenDevice");
                xiCloseDevice(xiH);

            }
        }
        
        
    }
xifinish:
    printf("Done\n");
    return self;
    
}



- (DWORD) CameraNumber {
    return num_camera;
}

- (HANDLE) InitiateDevice: (DWORD)deviceIdx{
    HANDLE xiH = NULL;
//   XI_RETURN stat = xiOpenDevice(XI_OPEN_BY_SN, [[NSString stringWithFormat:@"%d", deviceIdx] UTF8String], &xiH);
    XI_RETURN stat = xiOpenDevice(deviceIdx, &xiH);
    if (stat != XI_OK) {
        NSLog(@"Error opening XIMEA device %d", deviceIdx);
    }
    return xiH;
}

@end
