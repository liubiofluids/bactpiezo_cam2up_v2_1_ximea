//
//  fuzzyedge.cpp
//  imageToolbox
//
//  Created by Bin Liu on 11/14/15.
//
//

#include "fuzzyedge.h"
#include <math.h>
using namespace cv;



IplImage* CannyThreshold(IplImage* imgraw, int lowThreshold)
{
    Mat src_gray = cvarrToMat(imgraw);
    Mat dst, detected_edges;
    IplImage* imgedge=cvCreateImage(cvSize(imgraw->width, imgraw->height), imgraw->depth, imgraw->nChannels);
    
    int ratio = 3;
    int kernel_size = 3;
    /// Reduce noise with a kernel 3x3
    blur(src_gray, detected_edges, cvSize(6,6) );
    
    /// Canny detector
    Canny( detected_edges, detected_edges, lowThreshold, lowThreshold*ratio, kernel_size );
    double min, max;
    blur(detected_edges, detected_edges, cvSize(6,6) );
    //   GaussianBlur(detected_edges, detected_edges, cvSize(3, 3), 0, 0 );
    minMaxLoc(detected_edges, &min, &max);
//    printf("min: %f, max:%f\n", min, max);
    subtract(src_gray, .2*detected_edges, detected_edges);
    /// Using Canny's output as a mask, we display our result
//    printf("imgheader: %d\n", lowThreshold);
    //    imgedge = cvCloneImage((IplImage*)&detected_edges);
    IplImage imgt=cvIplImage(detected_edges);
    cvCopy(&imgt,imgedge);
    return imgedge;
}


