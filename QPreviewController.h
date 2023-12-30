//
//  QPreviewController.h
//  bacttrack
//
//  Created by Bin Liu on 8/12/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QPreviewView.h"
#import "ShowFrame.h"
#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#include <OpenGL/glu.h>

extern unsigned char *img_buffer;
extern unsigned char **pbuffer;

@interface QPreviewController : NSObject {
	IBOutlet ShowFrame *m_showframe; 
	IBOutlet QPreviewView *m_previewView;
    unsigned int m_camid;
	
}

- (void)update;

- (void)setBrightness: (float) brght;

- (void)setCameraID: (unsigned int) idcam;

@end
