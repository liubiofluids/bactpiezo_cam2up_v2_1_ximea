//
//  fuzzyedge.h
//  imageToolbox
//
//  Created by Bin Liu on 11/14/15.
//
//

#ifndef __imageToolbox__fuzzyedge__
#define __imageToolbox__fuzzyedge__

#define DIF_NEG 0
#define DIF_POS 1

#define NOT_EDGE 0
#define EDGE 1
#include "opencv2/opencv.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"

IplImage* CannyThreshold(IplImage* imgraw, int lowThreshold);

#endif /* defined(__imageToolbox__fuzzyedge__) */
