//
//  NSCvImage.h
//  bacttrack
//
//  Created by Bin Liu on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#import <Foundation/Foundation.h>

@interface NSCvImage : NSObject
{
    IplImage* m_imgobj;
    double m_frame_time;
}

- (IplImage*) getImage;
- (double) getTime;
- (id) initImage: (IplImage*) imgobj;
- (id) initImage: (IplImage*) imgobj timeInstance: (double) curr_time;
- (void) release;
@end
