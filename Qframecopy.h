/*
 *  Qframecopy.h
 *  bacttrack
 *
 *  Created by Bin Liu on 8/12/11.
 *  Copyright 2011 New York University. All rights reserved.
 *
 */
#include <opencv2/opencv.hpp>
#include <dc1394/dc1394.h>

void FrameCopyToRGBX
(
 const dc1394video_frame_t* , 
 void*				
 );

void FrameCopyMemToRGBX
(
 const unsigned char* , 
 void*				
 );

void FrameCopyMemToRGBX
(
 const unsigned char* , 
 void* , 
 unsigned int
 );

void FrameCopyMemToRGBXScaled
(
 const unsigned char* , 
 void*			,
 float
 );

void FrameCopyMemToRGBXNorm
(
 const unsigned char* ,
 void*
 );

void FrameCopyMemToRGBXNormInv
(
 const unsigned char* ,
 void*
 );

void F_Mono8
(
 const dc1394video_frame_t* , 	
 unsigned char* ,				
 unsigned char* ,			
 unsigned char* 			
 );

void F_Mono8Mem
(
 const unsigned char* , 	
 unsigned char* ,				
 unsigned char* ,			
 unsigned char* 			
 );

void F_Mono8Mem
(
 const unsigned char* , 	
 unsigned char* ,				
 unsigned char* ,			
 unsigned char* ,
 unsigned int
 );

void F_Mono8MemScaled
(
 const unsigned char* , 	
 unsigned char* ,				
 unsigned char* ,			
 unsigned char* ,
 float
 );

void F_Mono8MemNorm
(
 const unsigned char* ,
 unsigned char* ,
 unsigned char* ,
 unsigned char*
 );

void F_Mono8MemNormInv
(
 const unsigned char* ,
 unsigned char* ,
 unsigned char* ,
 unsigned char*
 );

void FrameSetTarget
(unsigned char*, 
 unsigned int, 
 unsigned int,
 unsigned int,
 unsigned int,
 unsigned int
 );

void RGBXToFrame
(
 void*				pBuffer,
 unsigned char*		cFrame
 );