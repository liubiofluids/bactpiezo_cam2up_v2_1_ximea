/*
 *  Qframecopy.cpp
 *  bacttrack
 *
 *  Created by Bin Liu on 8/12/11.
 *  Copyright 2011 New York University. All rights reserved.
 *
 */

#include "Qframecopy.h"
#include <math.h>

void FrameCopyToRGBX
(
 const dc1394video_frame_t*		pFrame,
 void*				pBuffer
 )
{
	unsigned char* p = ( unsigned char* ) pBuffer;
	F_Mono8( pFrame, p, p+1, p+2);
}

void F_Mono8
(
 const dc1394video_frame_t*			pFrame,
 unsigned char*				pDestRed,
 unsigned char*				pDestGreen,
 unsigned char*				pDestBlue
 )
{
	unsigned char*				pSrc;
	unsigned char*				pSrcEnd;
	unsigned int width;
	unsigned int height;
	width=pFrame->size[0];
	height=pFrame->size[1];
	
	pSrc = ( unsigned char* ) pFrame->image;
	pSrcEnd = pSrc + ( width * height );
	
	while ( pSrc < pSrcEnd )
	{
		unsigned char data = *pSrc;
		
		*pDestRed = data;
		*pDestGreen = data;
		*pDestBlue = data;
		
		pSrc++;
		pDestRed += 4;
		pDestGreen += 4;
		pDestBlue += 4;
	}
	
}

void FrameCopyMemToRGBX
(
 const unsigned char*		cFrame,
 void*				pBuffer
 )
{
	unsigned char* p = ( unsigned char* ) pBuffer;
	F_Mono8Mem( cFrame, p, p+1, p+2);
}

void FrameCopyMemToRGBX
(
 const unsigned char*		cFrame,
 void*				pBuffer,
 unsigned int size
 )
{
	unsigned char* p = ( unsigned char* ) pBuffer;
	F_Mono8Mem( cFrame, p, p+1, p+2, size);
}


void FrameCopyMemToRGBXScaled
(
 const unsigned char*		cFrame,
 void*				pBuffer,
 float brightness_multip
 )
{
	unsigned char* p = ( unsigned char* ) pBuffer;
    F_Mono8MemScaled( cFrame, p, p+1, p+2, brightness_multip);
}

void FrameCopyMemToRGBXNorm
(
 const unsigned char*		cFrame,
 void*				pBuffer
 )
{
    unsigned char* p = ( unsigned char* ) pBuffer;
    F_Mono8MemNorm( cFrame, p, p+1, p+2);
}

void FrameCopyMemToRGBXNormInv
(
 const unsigned char*		cFrame,
 void*				pBuffer
 )
{
    unsigned char* p = ( unsigned char* ) pBuffer;
    F_Mono8MemNormInv( cFrame, p, p+1, p+2);
}


void RGBXToFrame
(
 void*				pBuffer,
 unsigned char*		cFrame
 )
{
	unsigned char*				pSrc;
	unsigned char*				pSrcEnd;
	unsigned char*	pDestRed = (unsigned char*) pBuffer;
	extern int width;
	extern int height;
	
	pSrc = cFrame;
	pSrcEnd = pSrc + ( width * height );
//	printf("test: %d, %d, %d\n", (int)pSrc, (int)pSrcEnd, (int)pDestRed);
    int n=0;
	while ( pSrc < pSrcEnd )
	{
		*pSrc=*pDestRed;
		pSrc++;
        n++;
		pDestRed += 4;
	}
}

void F_Mono8Mem
(
 const unsigned char*			cFrame,
 unsigned char*				pDestRed,
 unsigned char*				pDestGreen,
 unsigned char*				pDestBlue
 )
{
	unsigned char*				pSrc;
	unsigned char*				pSrcEnd;
	extern int width;
	extern int height;
	
	pSrc = ( unsigned char* ) cFrame;
	pSrcEnd = pSrc + ( width * height );
	
	while ( pSrc < pSrcEnd )
	{
		unsigned char data = *pSrc;
		
		*pDestRed = data;
		*pDestGreen = data;
		*pDestBlue = data;
		
		pSrc++;
		pDestRed += 4;
		pDestGreen += 4;
		pDestBlue += 4;
	}
	
}

void F_Mono8Mem
(
 const unsigned char*			cFrame,
 unsigned char*				pDestRed,
 unsigned char*				pDestGreen,
 unsigned char*				pDestBlue,
 unsigned int size
 )
{
	unsigned char*				pSrc;
	unsigned char*				pSrcEnd;
//	extern int width;
//	extern int height;
	
	pSrc = ( unsigned char* ) cFrame;
	pSrcEnd = pSrc + ( size );
	
	while ( pSrc < pSrcEnd )
	{
		unsigned char data = *pSrc;
		
		*pDestRed = data;
		*pDestGreen = data;
		*pDestBlue = data;
		
		pSrc++;
		pDestRed += 4;
		pDestGreen += 4;
		pDestBlue += 4;
	}
	
}

void F_Mono8MemScaled
(
 const unsigned char*			cFrame,
 unsigned char*				pDestRed,
 unsigned char*				pDestGreen,
 unsigned char*				pDestBlue,
 float	brightness_multip
 )
{
	unsigned char*				pSrc;
	unsigned char*				pSrcEnd;
	extern int width;
	extern int height;
	
	pSrc = ( unsigned char* ) cFrame;
	pSrcEnd = pSrc + ( width * height );
	
	while ( pSrc < pSrcEnd )
	{
		unsigned char data = *pSrc;
		
		*pDestRed = data*brightness_multip;
		*pDestGreen = data*brightness_multip;
		*pDestBlue = data*brightness_multip;
		
		pSrc++;
		pDestRed += 4;
		pDestGreen += 4;
		pDestBlue += 4;
	}
	
}

void F_Mono8MemNorm
(
 const unsigned char*			cFrame,
 unsigned char*				pDestRed,
 unsigned char*				pDestGreen,
 unsigned char*				pDestBlue
 )
{
    unsigned char*				pSrc;
    unsigned char*				pSrcEnd;
    extern int width;
    extern int height;
    double cmax, cmin;
    
    pSrc = ( unsigned char* ) cFrame;
    pSrcEnd = pSrc + ( width * height );
    
    while ( pSrc < pSrcEnd )
    {
        int data = *pSrc;
        cmin = (data>cmin? cmin: data);
        cmax = (data<cmax? cmax: data);
        pSrc++;
    }
    float brightness_multip=255/(cmax-cmin+.1);

    pSrc = ( unsigned char* ) cFrame;
    while ( pSrc < pSrcEnd )
    {
        unsigned char data = *pSrc;
        
        *pDestRed = (int)((data-cmin)*brightness_multip);
        *pDestGreen = (int)((data-cmin)*brightness_multip);
        *pDestBlue = (int)((data-cmin)*brightness_multip);

        
        pSrc++;
        pDestRed += 4;
        pDestGreen += 4;
        pDestBlue += 4;
    }
    
}

void F_Mono8MemNormInv
(
 const unsigned char*			cFrame,
 unsigned char*				pDestRed,
 unsigned char*				pDestGreen,
 unsigned char*				pDestBlue
 )
{
    unsigned char*				pSrc;
    unsigned char*				pSrcEnd;
    extern int width;
    extern int height;
    double cmax, cmin;
    
    pSrc = ( unsigned char* ) cFrame;
    pSrcEnd = pSrc + ( width * height );
    
    while ( pSrc < pSrcEnd )
    {
        int data = *pSrc;
        cmin = (data>cmin? cmin: data);
        cmax = (data<cmax? cmax: data);
        pSrc++;
    }
    float brightness_multip=255/(cmax-cmin+.1);
    
    pSrc = ( unsigned char* ) cFrame;
    while ( pSrc < pSrcEnd )
    {
        unsigned char data = *pSrc;
        
        *pDestRed = (int)((cmax-data)*brightness_multip);
        *pDestGreen = (int)((cmax-data)*brightness_multip);
        *pDestBlue = (int)((cmax-data)*brightness_multip);
        
        
        pSrc++;
        pDestRed += 4;
        pDestGreen += 4;
        pDestBlue += 4;
    }
    
}

void FrameSetTarget
(
 unsigned char *m_alignedBufferPtr, 
 unsigned int x,
 unsigned int y, 
 unsigned int a,
 unsigned int m_width, 
 unsigned int m_height
 )
{
	unsigned int row;
	unsigned int col;
	unsigned int indx;
	unsigned char* pSrc = m_alignedBufferPtr;
	row = fmod(floor(y-0.5*a)+m_height, m_height);
	for(int i=0; i<a; i++)
	{
		col=fmod(floor(i+x-.5*a)+m_width, m_width);
		indx=4*(row*m_width+col);
		*(pSrc+indx)=0;
		*(pSrc+indx+1)=0;
		*(pSrc+indx+2)=255;
	}
	row = fmod(floor(y+0.5*a)+m_height, m_height);
	for(int i=0; i<a; i++)
	{
		col=fmod(floor(i+x-.5*a)+m_width, m_width);
		indx=4*(row*m_width+col);
		*(pSrc+indx)=0;
		*(pSrc+indx+1)=0;
		*(pSrc+indx+2)=255;
		
	}
	row = fmod(y+m_height, m_height);
	for(int i=0; i<11; i++)
	{
		col=fmod(floor(i+x-5.)+m_width, m_width);
		indx=4*(row*m_width+col);
		*(pSrc+indx)=0;
		*(pSrc+indx+1)=0;
		*(pSrc+indx+2)=255;
		
	}
	col = fmod(floor(x-0.5*a)+m_width, m_width);
	for(int i=0; i<a; i++)
	{
		row=fmod(floor((float)i+y-.5*a)+m_height, m_height);
		indx=4*(row*m_width+col);
		*(pSrc+indx)=0;
		*(pSrc+indx+1)=0;
		*(pSrc+indx+2)=255;
		
	}
	col = fmod(floor(x+0.5*a)+m_width, m_width);
	for(int i=0; i<a; i++)
	{
		row=fmod(floor(i+y-.5*a)+m_height, m_height);
		indx=4*(row*m_width+col);
		*(pSrc+indx)=0;
		*(pSrc+indx+1)=0;
		*(pSrc+indx+2)=255;
	}	
	
	col = fmod(x+m_width, m_width);
	for(int i=0; i<11; i++)
	{
		row=fmod(floor((float)i+y-5.)+m_height, m_height);
		indx=4*(row*m_width+col);
		*(pSrc+indx)=0;
		*(pSrc+indx+1)=0;
		*(pSrc+indx+2)=255;
	}
}


