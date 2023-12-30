//
//  NSCvImage.m
//  bacttrack
//
//  Created by Bin Liu on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSCvImage.h"

@implementation NSCvImage

- (IplImage*) getImage{
    return m_imgobj;
}

- (double) getTime{
    return m_frame_time;
}
- (id) initImage: (IplImage*) imgobj{
    m_imgobj=imgobj;
    return self;
}

- (id) initImage: (IplImage*) imgobj timeInstance: (double) curr_time{
    m_imgobj=imgobj;
    m_frame_time=curr_time;
    return self;
}

- (void) release {
/*    if(m_imgobj){
        cvReleaseImage(&m_imgobj);
    }
*/
}
@end
