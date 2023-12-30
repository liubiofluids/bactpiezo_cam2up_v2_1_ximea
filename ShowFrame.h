//
//  ShowFrame.h
//  bacttrack
//
//  Created by Bin Liu on 8/18/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern float camera_frame_rate;

extern int stage_x;
extern int stage_y;
extern int stage_z;

extern long long target_x;
extern long long target_y;
extern long long target_z;

@interface ShowFrame : NSView {
    
    unsigned int m_camid;
    
}

- (void) setCameraID :(int)camera_id;

@end
