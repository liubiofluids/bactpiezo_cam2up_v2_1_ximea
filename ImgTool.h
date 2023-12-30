/*
 *  ImgTool.h
 *  bacttrack
 *
 *  Created by Bin Liu on 8/19/11.
 *  Copyright 2011 New York University. All rights reserved.
 *
 */


#import <Cocoa/Cocoa.h>

#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

#import "Queue.h"
#include "fuzzyedge.h"

#define BDSize 10


@interface ImgTool: NSObject
{
	
}

- (IplImage*) Array2IplImageGray: (const unsigned char*)ImgBuff width: (unsigned int) m_width height :(unsigned int) m_height;

- (IplImage*) Normalize32: (IplImage*)img0;

- (IplImage*) Array2IplImageBW : (const unsigned char*) ImgBuff width: (unsigned int) m_width height: (unsigned int) m_height 
					  threshold: (double) threshold max: (double) maxValue threshold: (int) thresholdType ;
- (CvRect) getcvRect: (int) cx CY: (int) cy ROIwidth: (int) roiwidth ROIheight: (int) roiheight Imgwidth: (int) imgwidth Imgheight: (int) imgheight ; 

- (IplImage*) Img2BW: (IplImage*)img0 : (double) threshold : (int) max_val;

- (IplImage*) ImgBlur: (IplImage*)img0 : (double) rad_gauss;

- (IplImage*) Img2Edge: (IplImage*)img0 : (double) threshold : (int) max_val;

- (double) TrackClose:(IplImage *)imgbw : (int) area_min : (int) area_max: (CvPoint*) minPtr;

- (double) TrackClose:(IplImage *)imgbw : (IplImage *)img0 : (int) area_min : (int) area_max: (CvPoint*) minPtr: (CvRect*) pRect: (float*) pWeightedArea;

- (double) TrackCloseHole:(IplImage *)imgbw: (IplImage *)img0 : (int) area_min : (int) area_max: (CvPoint*) minPtr: (CvRect*) pRect: (float*) pWeightedArea: (float) fgeom: (double) time : (double) threshold;

- (double) TrackCloseIsland:(IplImage *)imgbw: (IplImage *)img0 : (int) area_min : (int) area_max: (CvPoint*) minPtr: (CvRect*) pRect: (float*) pWeightedArea;

- (void) ImgInvert: (IplImage*) img0;

- (void) TrackContour: (CvSeq*) contours: (int)width: (int)height: (int)area_min :(int)area_max :(CvPoint *)minPtr :(CvRect *)pRect: (BOOL) blhole: (float) fgeom;

- (bool) QuickScan: (IplImage *)imgbw: (BOOL) blhole: (int) area_min;

@end
//IplImage* Array2IplImageGray (const unsigned char* ImgBuff, unsigned int m_width, unsigned int m_height);




