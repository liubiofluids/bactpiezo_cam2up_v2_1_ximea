/*
 *  cvImage.h
 *  bacttrack
 *
 *  Created by Bin Liu on 9/28/11.
 *  Copyright 2011 New York University. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>

@interface cvImage: NSObject{
	
	IplImage* img;
}

- (void) init;

- (id) copyWithZone: (NSZone*) zone;

@end