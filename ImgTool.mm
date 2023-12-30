/*
 *  ImgTool.cpp
 *  bacttrack
 *
 *  Created by Bin Liu on 8/19/11.
 *  Copyright 2011 New York University. All rights reserved.
 *
 */

#import "ImgTool.h"

@implementation ImgTool

- (IplImage*) Array2IplImageGray :(const unsigned char*) ImgBuff width: (unsigned int) m_width height: (unsigned int) m_height 
{
	IplImage* piplimg = cvCreateImage(cvSize (m_width, m_height),
									  IPL_DEPTH_8U,
									  1);
	//	unsigned char* imghead=(unsigned char*) malloc(sizeof(unsigned char)*m_width*m_height);
	memcpy(piplimg->imageData, ImgBuff, sizeof(unsigned char)*m_width*m_height);
	//	piplimg->imageData=(char*) imghead;
	return piplimg;
}


- (IplImage*) Normalize32: (IplImage*) img0 
{
	
	IplImage* image_32F = cvCreateImage(cvGetSize(img0),IPL_DEPTH_32F,1);
	
	
	return image_32F;
}


- (IplImage*) Img2BW:(IplImage *)img0 :(double) threshold : (int) max_val{

    double imgmax, imgmin;
	CvPoint locmax, locmin;
	double imgnorm;
//    NSLog(@"img2bw: %d\n", img0->imageData);
	imgnorm=cvNorm(img0, NULL, CV_L1)/(double)(img0->width*img0->height);
    NSLog(@"imgnorm: %f", threshold*imgnorm);
    cvMinMaxLoc(img0, &imgmin, &imgmax, &locmin, &locmax);
    NSLog(@"img2bw: %f, %f\n", imgmin, imgmax);
    IplImage *img1=cvCreateImage(cvSize(img0->width, img0->height), img0->depth, img0->nChannels);
	cvThreshold( img0, img1, threshold*imgnorm, //(imgmin+imgmax),
				max_val, CV_THRESH_BINARY);
    cvMinMaxLoc(img1, &imgmin, &imgmax, &locmin, &locmax);
    return img1;
}


- (double) TrackClose:(IplImage *)imgbw : (int) area_min : (int) area_max: (CvPoint*) minPtr {
    static CvMemStorage* 	g_storage = NULL;
	
	if( g_storage == NULL ){
		g_storage = cvCreateMemStorage(0);
	} else {
		cvClearMemStorage( g_storage );
	}
	CvSeq* contours = 0;
	CvSeq* ptr = 0;
//	CvSeq* ptr_hole = 0; 
	float cx=imgbw->width*.5;
    float cy=imgbw->height*.5;
	CvRect newRect;
    CvRect minRect=cvRect(0,0,1,1);
    float distmin=cx+cy+cx+cy;
    distmin=distmin*distmin;
    float dist;
    CvPoint tracemin=cvPoint(-1,-1);
    CvPoint newPoint;
	cvFindContours( imgbw, g_storage, &contours, sizeof(CvContour),
				   CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE); 
    if(contours ){
//		CvScalar color = CV_RGB( 255, 255, 255);//rand()&255, rand()&255, rand()&255 );
//		int n=0;
		for(ptr=contours; ptr!=0; ptr=ptr->h_next){
			double area=fabs(cvContourArea(ptr));
//            NSLog(@"cid: %d, %f", n++, area);
			if(area>area_min && area<area_max){
//				NSLog(@"find bugs!\n");
                newRect=cvBoundingRect(ptr );
                newPoint=cvPoint(newRect.x+.5*newRect.width, newRect.y+.5*newRect.height);
                dist=(newPoint.x-cx)*(newPoint.x-cx)+(newPoint.y-cy)*(newPoint.y-cy);
                if (dist<distmin){
                    tracemin=newPoint;
                    minRect=newRect;
                    distmin=dist;
                }
			}
			else{
			}
		}
	}
    minPtr->x=tracemin.x; 
    minPtr->y=tracemin.y;
    CvRect old_ROI=cvGetImageROI(imgbw);
    cvSetImageROI(imgbw, minRect);
    CvScalar c=cvAvg(imgbw);
    cvSetImageROI(imgbw, old_ROI);
    return c.val[0];
}

- (IplImage*) Img2Edge:(IplImage *)img0 :(double) threshold : (int) max_val{
    
    double imgmax, imgmin;
    CvPoint locmax, locmin;
    double imgnorm;
    //    NSLog(@"img2bw: %d\n", img0->imageData);
    imgnorm=cvNorm(img0, NULL, CV_L1)/(double)(img0->width*img0->height);
//    NSLog(@"imgnorm: %f", imgnorm);
    cvMinMaxLoc(img0, &imgmin, &imgmax, &locmin, &locmax);
    //    NSLog(@"img2bw: %d, %d\n", imgmin, imgmax);
    //      NSLog(@"imgnorm: %f", imgnorm);
    IplImage *img1=CannyThreshold(img0,  (int)(.5*(1.-threshold)*imgnorm));
    return img1;
}

- (IplImage*) ImgBlur:(IplImage *)img0 :(double) rad_gauss{
    IplImage *img1=cvCreateImage(cvSize(img0->width, img0->height), img0->depth, img0->nChannels);
    /// Applying Gaussian blur
    int irad=(int)floor(rad_gauss+.5);
    cv::Mat src=cv::cvarrToMat(img0); cv::Mat dst=cv::cvarrToMat(img1);
    cv::GaussianBlur (src, dst, cv::Size(2*irad+1, 2*irad+1), 0, 0);
    return img1;
}

- (double) TrackClose:(IplImage *)imgbw: (IplImage *)img0 : (int) area_min : (int) area_max: (CvPoint*) minPtr: (CvRect*) pRect: (float*) pWeightedArea
{
    static CvMemStorage* 	g_storage = NULL;
	
	if( g_storage == NULL ){
		g_storage = cvCreateMemStorage(0);
	} else {
		cvClearMemStorage( g_storage );
	}
	CvSeq* contours = 0;
	CvSeq* ptr = 0;
//	CvSeq* ptr_hole = 0; 
	float cx=imgbw->width*.5;
    float cy=imgbw->height*.5;
    double M00, M01, M10;
    int crdx, crdy;
    CvMoments moments;
	CvRect newRect;
//    CvRect minRect=cvRect(0,0,1,1);
    float distmin=cx+cy+cx+cy;
    distmin=distmin*distmin;
    float dist;
    CvPoint tracemin=cvPoint(-1,-1);
    CvPoint newPoint;
    CvScalar s;
    CvScalar s1;
    
    
//    double imgmax, imgmin;
//    CvPoint locmax, locmin;
    
//    cvMinMaxLoc(imgbw, &imgmin, &imgmax, &locmin, &locmax);
    
//    NSLog(@"Max: %f", imgmax);
    
    IplImage* imgbw2=cvCreateImage(cvSize(imgbw->width, imgbw->height), imgbw->depth, imgbw->nChannels);
    cvCopy(imgbw, imgbw2);
	cvFindContours( imgbw, g_storage, &contours, sizeof(CvContour),
				   CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE); 
    
//    cvMinMaxLoc(imgbw, &imgmin, &imgmax, &locmin, &locmax);
    
//    NSLog(@"Max: %f", imgmax);
    
    if(contours ){
//		CvScalar color = CV_RGB( 255, 255, 255);//rand()&255, rand()&255, rand()&255 );
//		int n=0;
		for(ptr=contours; ptr!=0; ptr=ptr->h_next){
			double area=fabs(cvContourArea(ptr));
            //            NSLog(@"cid: %d, %f", n++, area);
			if(area>area_min && area<area_max){
                //				NSLog(@"find bugs!\n");
                newRect=cvBoundingRect(ptr );
                newPoint=cvPoint(newRect.x+.5*newRect.width, newRect.y+.5*newRect.height);
                dist=(newPoint.x-cx)*(newPoint.x-cx)+(newPoint.y-cy)*(newPoint.y-cy);
                if (dist<distmin && area>0.25*(newRect.width*newRect.height)){
                    tracemin.x=newPoint.x;
                    tracemin.y=newPoint.y;  
                    pRect->x=newRect.x;
                    pRect->y=newRect.y;
                    pRect->width=newRect.width;
                    pRect->height=newRect.height;
                    distmin=dist;
                    cvMoments(ptr, &moments);
                    M00 = cvGetSpatialMoment(&moments, 0, 0);
                    M10 = cvGetSpatialMoment(&moments, 1, 0);
                    M01 = cvGetSpatialMoment(&moments, 0, 1);
                    crdx=(int)(M10/M00);
                    crdy=(int)(M01/M00);
                }
			}
			else{
			}
		}
	}


    if (1){// (tracemin.x==-1){
        minPtr->x=tracemin.x;
        pRect->x=imgbw->width*.5;
        pRect->y=imgbw->height*.5;
        pRect->width=0;
        pRect->height=0;
        cvReleaseImage(&imgbw2);
        return 0;
    }
    else{
        CvRect old_ROI=cvGetImageROI(img0);
    //    NSLog(@"crd: %d, %d, %d, %d", imgbw->width, imgbw->height,  crdx, crdy);
        s=cvGet2D(imgbw, crdy, crdx);
//      NSLog(@"bwcrd: %f", s.val[0]);
//        s1=cvGet2D(img0, crdy, crdx);
//        NSLog(@"imgcrd: %f", s1.val[0]);
        
        cvSetImageROI(img0, *pRect);
        cvSetImageROI(imgbw2, *pRect);
        IplImage* imgbw1=cvCreateImage(cvSize(pRect->width, pRect->height), imgbw->depth, imgbw->nChannels);
        IplImage* imgbw3=cvCreateImage(cvSize(pRect->width, pRect->height), imgbw->depth, imgbw->nChannels);
        if (s.val[0]==0){ //hole
            NSLog(@"hole: ");
            cvSet(imgbw3, cvScalar(1));
            cvSub(imgbw3, imgbw2, imgbw3); //inverse the matrix
        }
        else
        {
            cvCopy(imgbw2, imgbw3);
        }
        CvScalar c0=cvSum(img0);
//        cvConvertScale(imgbw, imgbw, 1/255.);
//        NSLog(@"imgcrd: %d, %d, %d, %d", crdy-pRect->y, crdx-pRect->x, pRect->height, pRect->width );
        s1=cvGet2D(imgbw3, crdy-pRect->y, crdx-pRect->x);
        NSLog(@"imgcrd: %d, %d, %f", pRect->width, pRect->height, s1.val[0]);
//        s1=cvGet2D(imgbw1, crdy-pRect->y, crdx-pRect->x);
//        NSLog(@"imgcrd: %f", s1.val[0]);
        cvMul(img0, imgbw3, imgbw1);
//        s1=cvGet2D(imgbw1, crdy-pRect->y, crdx-pRect->x);
//        NSLog(@"imgcrd: %f", s1.val[0]);

        CvScalar c1=cvSum(imgbw1);
        CvScalar c2=cvSum(imgbw3);
        cvSetImageROI(img0, old_ROI);
        cvSetImageROI(imgbw, old_ROI);
        cvSetImageROI(imgbw2,  old_ROI);
        int area_tot=imgbw3->width*imgbw3->height;

//        cvMinMaxLoc(imgbw3, &imgmin, &imgmax, &locmin, &locmax);
        
//        NSLog(@"Max: %f", imgmax);
        
        cvReleaseImage(&imgbw1);
        cvReleaseImage(&imgbw2);
        cvReleaseImage(&imgbw3);
        minPtr->x=crdx; 
        minPtr->y=crdy;
        *pWeightedArea=c2.val[0];
        return c1.val[0]*(area_tot-c2.val[0])/c2.val[0]/(c0.val[0]-c1.val[0]);
        
    }
}


- (double) TrackCloseHole:(IplImage *)imgbw: (IplImage *)img0 : (int) area_min : (int) area_max: (CvPoint*) minPtr: (CvRect*) pRect: (float*) pWeightedArea: (float) fgeom: (double) time: (double) threshold
{
    static CvMemStorage* 	g_storage = NULL;
    static double* darkrel_buff=NULL;
    static double* darkrel_buff_t=NULL;
    static double* buff_t=NULL;
    static double* time_buff=NULL;
    static double* posx_buff=NULL;
    static double* posy_buff=NULL;
    static int siz_buff=0;
    static int siz_buff_max=3;
    static double sum_buff=0.;
    
    if( g_storage == NULL ){
		g_storage = cvCreateMemStorage(0);
	} else {
		cvClearMemStorage( g_storage );
	}
    
    if( darkrel_buff==NULL){
        darkrel_buff=(double*) malloc(sizeof(double)*siz_buff_max);
        darkrel_buff_t=(double*) malloc(sizeof(double)*siz_buff_max);
        buff_t=(double*) malloc(sizeof(double)*siz_buff_max);
        time_buff=(double*) malloc(sizeof(double)*siz_buff_max);
        posx_buff=(double*) malloc(sizeof(double)*siz_buff_max);
        posy_buff=(double*) malloc(sizeof(double)*siz_buff_max);
    }
	CvSeq* contours = 0;
	CvSeq* ptr = 0;
	CvSeq* ptr_hole = 0; 
	float cx=imgbw->width*.5;
    float cy=imgbw->height*.5;
    double M00, M01, M10;

    double crdx, crdy;
    float distmin=cx+cy+cx+cy;
    distmin=distmin*distmin;
    float dist;
    CvPoint tracemin=cvPoint(-1,-1);
    double dark_rel;

    CvMoments moments;
    

    IplImage* imgbw2=cvCreateImage(cvSize(imgbw->width, imgbw->height), imgbw->depth, imgbw->nChannels);


    if ([self QuickScan:imgbw :true :area_min]){
        cvCopy(imgbw, imgbw2, NULL);
        cvFindContours( imgbw, g_storage, &contours, sizeof(CvContour),
                       CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);
    }
    else{
        NSLog(@"edge detection applied");
        IplImage* imgt1; //=cvCreateImage(cvSize(img0->width, img0->height), img0->depth, img0->nChannels); //cause memeory leak here. 20160228
        imgt1= [self Img2Edge:img0 :threshold: 255];
        IplImage* imgt2;
        imgt2 = [self Img2BW:imgt1:threshold: 255];

        cvCopy(imgt2, imgbw2, NULL);
        cvFindContours( imgt2, g_storage, &contours, sizeof(CvContour),
                       CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);

        cvReleaseImage(&imgt1);
        cvReleaseImage(&imgt2);
    }
    //    cvMinMaxLoc(imgbw, &imgmin, &imgmax, &locmin, &locmax);
    
    //    NSLog(@"Max: %f", imgmax);
    
    [self TrackContour:contours : imgbw->width : imgbw->height : area_min : area_max : &tracemin : pRect: true: fgeom];

    NSLog(@"tracemin:%d", tracemin.x);
    if (tracemin.x==-1){
        minPtr->x=tracemin.x;
        pRect->x=imgbw->width*.5;
        pRect->y=imgbw->height*.5;
        pRect->width=0;
        pRect->height=0;
        cvReleaseImage(&imgbw2);
        siz_buff=0;
        memset(darkrel_buff, 0, sizeof(double)*siz_buff_max);
        memset(darkrel_buff_t, 0, sizeof(double)*siz_buff_max);
        sum_buff=0.;
        return 0;
    }
    else{
        CvRect old_ROI=cvGetImageROI(img0);
        //    NSLog(@"crd: %d, %d, %d, %d", imgbw->width, imgbw->height,  crdx, crdy);
        //   s=cvGet2D(imgbw, crdy, crdx);
        //      NSLog(@"bwcrd: %f", s.val[0]);
        //        s1=cvGet2D(img0, crdy, crdx);
        //        NSLog(@"imgcrd: %f", s1.val[0]);
        NSLog(@"roi: %d, %d, %d, %d", pRect->x, pRect->y, pRect->width, pRect->height);
        cvSetImageROI(img0, *pRect);
        cvSetImageROI(imgbw2, *pRect);
        IplImage* imgbw1=cvCreateImage(cvSize(pRect->width, pRect->height), imgbw->depth, imgbw->nChannels);
        IplImage* imgbw3=cvCreateImage(cvSize(pRect->width, pRect->height), imgbw->depth, imgbw->nChannels);
        /*if (s.val[0]==0){ //hole
            NSLog(@"hole: ");
            cvSet(imgbw3, cvScalar(1));
            cvSub(imgbw3, imgbw2, imgbw3); //inverse the matrix
        }
        else
        {
            cvCopy(imgbw2, imgbw3);
        }
         */
        cvSet(imgbw3, cvScalar(1));
        cvSub(imgbw3, imgbw2, imgbw3); //inverse the matrix
        CvScalar c0=cvSum(img0);
        //        cvConvertScale(imgbw, imgbw, 1/255.);
        //        NSLog(@"imgcrd: %d, %d, %d, %d", crdy-pRect->y, crdx-pRect->x, pRect->height, pRect->width );
        //s1=cvGet2D(imgbw3, crdy-pRect->y, crdx-pRect->x);
        //NSLog(@"imgcrd: %d, %d, %f", pRect->width, pRect->height, s1.val[0]);
        //        s1=cvGet2D(imgbw1, crdy-pRect->y, crdx-pRect->x);
        //        NSLog(@"imgcrd: %f", s1.val[0]);
        cvMul(img0, imgbw3, imgbw1);
        //        s1=cvGet2D(imgbw1, crdy-pRect->y, crdx-pRect->x);
        //        NSLog(@"imgcrd: %f", s1.val[0]);
        
        CvScalar c1=cvSum(imgbw1);
        CvScalar c2=cvSum(imgbw3);
        cvSetImageROI(img0, old_ROI);
        cvSetImageROI(imgbw, old_ROI);
        cvSetImageROI(imgbw2,  old_ROI);
        int area_tot=imgbw3->width*imgbw3->height;

        cvReleaseImage(&imgbw1);
        cvReleaseImage(&imgbw2);
        cvReleaseImage(&imgbw3);
        minPtr->x=pRect->x+(int)floor(.5*pRect->width);
        minPtr->y=pRect->y+(int)floor(.5*pRect->height);
        *pWeightedArea=c2.val[0];
        if (c2.val[0]>=area_min){
            dark_rel =c1.val[0]*(area_tot-c2.val[0])/c2.val[0]/(c0.val[0]-c1.val[0]);
        }
        else{
            dark_rel =(c1.val[0]*(area_tot-area_min)+c0.val[0]*(area_min-c2.val[0]))/(c0.val[0]-c1.val[0])/area_min; //use area_min as the cuttoff area for computing the darkness
        }
        //NSLog(@"sumbuf: %f, %d", darkrel_buff[siz_buff], siz_buff);
        if (siz_buff==siz_buff_max){
            sum_buff=sum_buff-darkrel_buff[siz_buff-1];
        }
        sum_buff=sum_buff+dark_rel;
        
        memcpy(darkrel_buff_t+1, darkrel_buff, sizeof(double)*(siz_buff_max-1));
       
        memcpy(darkrel_buff, darkrel_buff_t, sizeof(double)*siz_buff_max);
        // NSLog(@"sumbuf: %f, %d", darkrel_buff[1], siz_buff);

        *darkrel_buff=dark_rel;
        //NSLog(@"sumbuf: %f, %d", darkrel_buff[0], siz_buff);
        if (siz_buff<siz_buff_max) {
            siz_buff++;
        }
        dark_rel=sum_buff/siz_buff;

        NSLog(@"sumbuf: %f, %f", sum_buff/siz_buff, dark_rel);
        return dark_rel;
    }
}

- (double) TrackCloseIsland:(IplImage *)imgbw: (IplImage *)img0 : (int) area_min : (int) area_max: (CvPoint*) minPtr: (CvRect*) pRect: (float*) pWeightedArea
{
    static CvMemStorage* 	g_storage = NULL;
    
	if( g_storage == NULL ){
		g_storage = cvCreateMemStorage(0);
	} else {
		cvClearMemStorage( g_storage );
	}

	CvSeq* contours = 0;
	CvSeq* ptr = 0;
//	CvSeq* ptr_hole = 0; 
	float cx=imgbw->width*.5;
    float cy=imgbw->height*.5;
    double M00, M01, M10, M20, M02, M11, l1, l2, th_major;
//    double darkness_exp;
    double crdx, crdy;
//    CvRect minRect=cvRect(0,0,1,1);
    float distmin=cx+cy+cx+cy;
    distmin=distmin*distmin;
    float dist;
    CvPoint tracemin=cvPoint(-1,-1);
    double dark_rel;
//    CvScalar s;
//    CvScalar s1;
    CvMoments moments;
    
    //    double imgmax, imgmin;
    //    CvPoint locmax, locmin;
    
    //    cvMinMaxLoc(imgbw, &imgmin, &imgmax, &locmin, &locmax);
    
    //    NSLog(@"Max: %f", imgmax);
    
    IplImage* imgbw2=cvCreateImage(cvSize(imgbw->width, imgbw->height), imgbw->depth, imgbw->nChannels);
    cvCopy(imgbw, imgbw2);

	cvFindContours( imgbw, g_storage, &contours, sizeof(CvContour),
				   CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE); 
    
    //    cvMinMaxLoc(imgbw, &imgmin, &imgmax, &locmin, &locmax);
    
    //    NSLog(@"Max: %f", imgmax);
//    int n=0;
    if(contours ){
//		CvScalar color = CV_RGB( 255, 255, 255);//rand()&255, rand()&255, rand()&255 );
		
		for(ptr=contours; ptr!=0; ptr=ptr->h_next){
            CvRect newRect;
            CvPoint newPoint;
            
            double area=fabs(cvContourArea(ptr));
            //NSLog(@"island: %d, %f", n++, area);
            if(area>area_min && area<area_max){
                //				NSLog(@"find bugs!\n");
                newRect=cvBoundingRect(ptr);
                newPoint.x=newRect.x+.5*newRect.width;
                newPoint.y=newRect.y+.5*newRect.height;
                dist=(newPoint.x-cx)*(newPoint.x-cx)+(newPoint.y-cy)*(newPoint.y-cy);
                if (dist<distmin && area>0.3*(newRect.width*newRect.height)){
                    cvMoments(ptr, &moments);
                    M00 = cvGetSpatialMoment(&moments, 0, 0);
                    M10 = cvGetSpatialMoment(&moments, 1, 0);
                    M01 = cvGetSpatialMoment(&moments, 0, 1);
                    crdx=(M10/M00);
                    crdy=(M01/M00);
                    M11 = cvGetSpatialMoment(&moments, 1, 1)/M00-crdx*crdy;
                    M20 = cvGetSpatialMoment(&moments, 2, 0)/M00-crdx*crdx;
                    M02 = cvGetSpatialMoment(&moments, 0, 2)/M00-crdy*crdy;
                    l1=0.5*(M02+M20);
                    l2=l1-.5*sqrt((M20-M02)*(M20-M02)+4.*M11*M11);
                    l1=l1+.5*sqrt((M20-M02)*(M20-M02)+4.*M11*M11);
                    th_major=atan(M11/(M20-l2));
                    if (l1<90 && l2<9 && l2>2){
                    //NSLog(@"pa: %f, %f", l1, l2);
                        tracemin.x=newPoint.x;
                        tracemin.y=newPoint.y;
                        pRect->x=newRect.x;
                        pRect->y=newRect.y;
                        pRect->width=newRect.width;
                        pRect->height=newRect.height;
                        distmin=dist;
                    }
                }
                else{
                }
            }
        }
    }   
        
        if (tracemin.x==-1){
            minPtr->x=tracemin.x;
            pRect->x=imgbw->width*.5;
            pRect->y=imgbw->height*.5;
            pRect->width=0;
            pRect->height=0;
            cvReleaseImage(&imgbw2);
        }
        else{
            CvRect old_ROI=cvGetImageROI(img0);
            //    NSLog(@"crd: %d, %d, %d, %d", imgbw->width, imgbw->height,  crdx, crdy);
            //   s=cvGet2D(imgbw, crdy, crdx);
            //      NSLog(@"bwcrd: %f", s.val[0]);
            //        s1=cvGet2D(img0, crdy, crdx);
            //        NSLog(@"imgcrd: %f", s1.val[0]);
            
            cvSetImageROI(img0, *pRect);
            cvSetImageROI(imgbw2, *pRect);
            IplImage* imgbw1=cvCreateImage(cvSize(pRect->width, pRect->height), imgbw->depth, imgbw->nChannels);
            IplImage* imgbw3=cvCreateImage(cvSize(pRect->width, pRect->height), imgbw->depth, imgbw->nChannels);
            /*if (s.val[0]==0){ //hole
             NSLog(@"hole: ");
             cvSet(imgbw3, cvScalar(1));
             cvSub(imgbw3, imgbw2, imgbw3); //inverse the matrix
             }
             else
             {
             cvCopy(imgbw2, imgbw3);
             }
             */
            cvSet(imgbw3, cvScalar(1));
            cvSub(imgbw3, imgbw2, imgbw3); //inverse the matrix
            CvScalar c0=cvSum(img0);
            //        cvConvertScale(imgbw, imgbw, 1/255.);
            //        NSLog(@"imgcrd: %d, %d, %d, %d", crdy-pRect->y, crdx-pRect->x, pRect->height, pRect->width );
            //s1=cvGet2D(imgbw3, crdy-pRect->y, crdx-pRect->x);
            //NSLog(@"imgcrd: %d, %d, %f", pRect->width, pRect->height, s1.val[0]);
            //        s1=cvGet2D(imgbw1, crdy-pRect->y, crdx-pRect->x);
            //        NSLog(@"imgcrd: %f", s1.val[0]);
            cvMul(img0, imgbw2, imgbw1);
            //        s1=cvGet2D(imgbw1, crdy-pRect->y, crdx-pRect->x);
            //        NSLog(@"imgcrd: %f", s1.val[0]);
            
            CvScalar c1=cvSum(imgbw1);
            CvScalar c2=cvSum(imgbw2);
            cvSetImageROI(img0, old_ROI);
            cvSetImageROI(imgbw, old_ROI);
            cvSetImageROI(imgbw2,  old_ROI);
            int area_tot=imgbw3->width*imgbw3->height;
            
            //        cvMinMaxLoc(imgbw3, &imgmin, &imgmax, &locmin, &locmax);
            
            //        NSLog(@"Max: %f", imgmax);
            
            cvReleaseImage(&imgbw1);
            cvReleaseImage(&imgbw2);
            cvReleaseImage(&imgbw3);
            minPtr->x=(int)floor(crdx+.5); 
            minPtr->y=(int)floor(crdy+.5);
            *pWeightedArea=c2.val[0];
            dark_rel =c1.val[0]*(area_tot-c2.val[0])/c2.val[0]/(c0.val[0]-c1.val[0]);
            NSLog(@"island: %f", dark_rel);
            
            
        }
    return dark_rel;
}


- (IplImage*) Array2IplImageBW : (const unsigned char*) ImgBuff width: (unsigned int) m_width height: (unsigned int) m_height threshold: (double) threshold 
							max: (double) maxValue threshold: (int) thresholdType //CV_THRESH_BINARY
{
	IplImage* piplimg = cvCreateImage(cvSize (m_width, m_height),
									  IPL_DEPTH_8U,
									  1);
	memcpy(piplimg->imageData, ImgBuff, sizeof(unsigned char)*m_width*m_height);
	cvThreshold(piplimg, piplimg, threshold, maxValue, thresholdType);
	
	
	return piplimg;
}

- (CvRect) getcvRect: (int) cx CY: (int) cy ROIwidth: (int) roiwidth ROIheight: (int) roiheight Imgwidth: (int) imgwidth Imgheight: (int) imgheight 
{
    int x=(int)floor(cx-0.5*roiwidth);
    int y=(int)floor(cy-0.5*roiheight);
    int awidth;
    int aheight;
    CvRect mrect;
    if (x<0){
        x=0;
    }
    else if (x>=imgwidth)
    {
        x=imgwidth-1;
    }
    if (y<0){
        y=0;
    }
    else if (y>=imgheight)
    {
        y=imgheight-1;
    }
    if (x+roiwidth>imgwidth){
        awidth=imgwidth-x;
    }
    else{
        awidth=roiwidth;
    }
    if (y+roiheight>imgheight){
        aheight=imgheight-y;
    }
    else{
        aheight=roiheight;
    }
//    NSLog(@"getROI: %d, %d, %d, %d, %d, %d", imgwidth, imgheight, roiwidth,roiheight, x, y);
    mrect=cvRect(x,y,awidth, aheight);
    return mrect;
}

- (void) ImgInvert: (IplImage*) img0
{
    IplImage* img1 = cvCreateImage( cvSize( img0->width, img0->height ), img0->depth, img0->nChannels );
    cvSet(img1, cvScalar(255));
    cvSub(img1, img0, img0);
}

- (void) TrackContour: (CvSeq*) contours: (int)rwidth: (int)rheight: (int)area_min :(int)area_max :(CvPoint *)tracemin :(CvRect *)pRect: (BOOL) blhole: (float) fgeom
{
    CvSeq* ptr = 0;
    CvSeq* ptr_hole = 0;
    CvMoments moments;
    float dist;
    float cx=.5*rwidth;
    float cy=.5*rheight;
    float distmin=cx+cy+cx+cy;
    distmin=distmin*distmin;
    double M00, M01, M10;
    double crdx, crdy;
    //    double M02, M20, M11;
//    NSLog(@"contour id: %ld", contours);
    if(contours ){
        //		CvScalar color = CV_RGB( 255, 255, 255);//rand()&255, rand()&255, rand()&255 );
        //		int n=0;
        for(ptr=contours; ptr!=0; ptr=ptr->h_next){
            if (blhole){
                ptr_hole=ptr->v_next;
            }
            else{
                ptr_hole=ptr;
            }
//            NSLog(@"hole id: %ld", ptr_hole);
            while(ptr_hole){
                
                CvRect newRect;
                CvPoint newPoint;
                double area=fabs(cvContourArea(ptr_hole));
//                NSLog(@"area: %f", area);
                if(area>area_min && area<area_max){
                    //				NSLog(@"find bugs!\n");
                    newRect=cvBoundingRect(ptr_hole);
                    newPoint.x=newRect.x+.5*newRect.width;
                    newPoint.y=newRect.y+.5*newRect.height;
                    dist=(newPoint.x-cx)*(newPoint.x-cx)+(newPoint.y-cy)*(newPoint.y-cy);
                    //                   NSLog(@"distmin 1: %f, %f", dist, distmin);
                    if (dist<distmin && area>fgeom*(newRect.width*newRect.height)){
                        //NSLog(@"distmin 2: %f, %f", dist, distmin);
                        /*cvMoments(ptr_hole, &moments);
                        M00 = cvGetSpatialMoment(&moments, 0, 0);
                        M10 = cvGetSpatialMoment(&moments, 1, 0);
                        M01 = cvGetSpatialMoment(&moments, 0, 1);
                        crdx=(M10/M00);
                        crdy=(M01/M00);
                         */
                        /*    M11 = cvGetSpatialMoment(&moments, 1, 1)/M00-crdx*crdy;
                         M20 = cvGetSpatialMoment(&moments, 2, 0)/M00-crdx*crdx;
                         M02 = cvGetSpatialMoment(&moments, 0, 2)/M00-crdy*crdy;
                         l1=0.5*(M02+M20);
                         l2=l1-.5*sqrt((M20-M02)*(M20-M02)+4.*M11*M11);
                         l1=l1+.5*sqrt((M20-M02)*(M20-M02)+4.*M11*M11);
                         th_major=atan(M11/(M20-l2));
                         if (l1<90 && l2<9 && l2>4){
                         //NSLog(@"pa: %f, %f", l1, l2);
                         */
                        tracemin->x=newPoint.x;
                        tracemin->y=newPoint.y;
                        /* make the bounding box 5 pixels larger than tight bounding */
                        pRect->x=fmax(0, newRect.x-5);
                        pRect->y=fmax(0, newRect.y-5);
                        pRect->width=fmin(newRect.width+10+pRect->x, rwidth)-pRect->x;
                        pRect->height=fmin(newRect.height+10+pRect->y, rheight)-pRect->y;
                        distmin=dist;
                        /*  }
                         */
                        
                    }
                }
                else{
                }
                ptr_hole=ptr_hole->h_next;
            }
        }
    }

}


- (bool) QuickScan: (IplImage *)imgbw: (BOOL) blhole: (int) area_min
{
    BOOL existhole=false;
    CvSeq* contours = 0;
    CvSeq* ptr = 0;
    CvSeq* ptr_hole = 0;
    
    static CvMemStorage* 	g_storage = NULL;
    
    if( g_storage == NULL ){
        g_storage = cvCreateMemStorage(0);
    } else {
        cvClearMemStorage( g_storage );
    }
    IplImage* imgbw2=cvCreateImage(cvSize(imgbw->width, imgbw->height), imgbw->depth, imgbw->nChannels);
    
    cvCopy(imgbw, imgbw2, NULL);
    
    cvFindContours( imgbw2, g_storage, &contours, sizeof(CvContour),
                   CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);
    if(contours ){
        //		CvScalar color = CV_RGB( 255, 255, 255);//rand()&255, rand()&255, rand()&255 );
        //		int n=0;
        for(ptr=contours; ptr!=0; ptr=ptr->h_next){
            if (blhole){
                ptr_hole=ptr->v_next;
            }
            else{
                ptr_hole=ptr;
            }
            
            while(ptr_hole){
                
                CvRect newRect;
                CvPoint newPoint;
                double area=fabs(cvContourArea(ptr_hole));
                if(area>area_min){
                    existhole=TRUE;
                }
                else{
                }
                ptr_hole=ptr_hole->h_next;
            }
        }
    }
    return existhole;
}
@end