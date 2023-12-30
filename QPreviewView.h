/*
|==============================================================================
| Copyright (C) 2002 Quantitative Imaging Corporation.  All Rights Reserved.
| Reproduction or disclosure of this file or its contents without the prior
| written consent of Quantitative Imaging Corporation is prohibited.
|==============================================================================
|
| File:			QPreviewView.h
|
| Project/lib:	Mac OS X Cocoa Demo Project
|
| Target:		Mac OS X
|
| Description:	The preview view that implements an OpenGL view.
|
| Notes:		This example is to demonstrate accessing and using the
|				CamApi from within a Cocoa Application.
|
|				NOTE: This is a very simple example of a preview view.
|				A full blown version of a preview view should take into
|				image size changes.  If possible to the design, it should
|				also try to use the buffer supplied in the QCam_Frame.
|				This way, it can avoid a copy from the frame buffer to 
|				a temporary buffer each update.  This slows down the
|				preview considerably.
|
|==============================================================================
| dd/mon/yy  Author		Notes
|------------------------------------------------------------------------------
| 08/Oct/02  JonS		Original.
|==============================================================================
*/

#import <Cocoa/Cocoa.h>
#import "PhidgetStepperController.h"
#include <dc1394/dc1394.h>
#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#include <OpenGL/glu.h>

#import "ImgTool.h"	
#import "CameraList.h"

extern NSLock *m_lock;
extern NSLock **plock;
extern NSLock *buffer_lock;
extern NSLock *stage_lock;
extern NSLock *trace_lock;
extern unsigned int width; 
extern unsigned int height;
extern unsigned int width0;
extern unsigned int height0;
extern long long target_x;
extern long long target_y;
extern long long target_z;
extern long long target_a;
extern long long actual_x;
extern long long actual_y;
extern long long actual_z;
extern long long actual_depth;
extern long long target_depth;
extern float* m_brightness_multip;
extern float unit_xlen;
extern float unit_zlen;
extern bool flagfullscreen;
extern PhidgetStepperHandle* m_stepper_x;
extern PhidgetStepperHandle* m_stepper_y;
extern PhidgetStepperHandle* m_stepper_z;
extern bool flagstage;
extern bool flagauto;
extern float trace_x;
extern float trace_y;
extern bool flag_tracelocked;
extern bool flag_imgszupdted;
extern bool flag_capture;
extern camstats* camera_info;

extern NSLock* piezo_lock;
extern float target_piezo;
extern float actual_piezo;

@interface QPreviewView : NSOpenGLView
{
	// We want to know when we are receiving the first
	// frame.
    bool m_first;
	
	// This stores that we have a frame loaded.  This prevents
	// the view from trying to draw an uninitialized buffer.
    bool m_loaded;
	
	// A temporary buffer to store our image data in
    unsigned char *m_buffer;
	unsigned char *m_buffer_full;
	// A pointer to m_buffer but ensures that it is aligned on
	// the correct boundary.  Used for OpenGL.
    unsigned char *m_alignedBufferPtr;
	unsigned char *m_alignedBufferPtr_full;
    unsigned char *m_alignedBufferPtr_curr;
	// The size of the current image
    uint32_t m_imageSize;
	
	// A temporary buffer used to store the image.
    uint32_t m_bufferSize;
	
	// Stores the image height and width
    uint32_t m_width;
    uint32_t m_height;
            
	// Is a mutex lock to ensure that the buffer is not being updated
	// while it is being written to.
	
	NSOpenGLContext *m_GLContext; 
	GLuint	m_texture;
	NSMutableSet * keysPressed;
	int old_x;
	int old_y;
	int old_z;
	IBOutlet PhidgetStepperController* m_stepper_1;
	IBOutlet PhidgetStepperController* m_stepper_2;
	IBOutlet PhidgetStepperController* m_stepper_3;
	IBOutlet ImgTool *m_imgResize;
	NSCursor *m_dragCursor;
	NSCursor *m_moveCursor;
    IBOutlet NSButtonCell *m_button_track_manual;
    IBOutlet NSButtonCell *m_button_track_auto;
    IBOutlet NSMatrix *m_button_track_switch;
    IBOutlet id iautocontrast;
    IBOutlet id icb_inverse;
    NSLock* m_keyboard_lock;
    bool flag_monitor_keys;
    long long count_key;
    float m_brghtnss;
    unsigned int m_camid;
}

// Imports a new frame to be displayed
//- (void)importFrame: (QCam_Frame *)frame;

- (void)importFrame: (unsigned char *) frame_buffer; 

// Initializes the preview view.  This is called when the nib is being loaded
- (id)initWithFrame:(NSRect)frameRect;

// Called to update the preview view.
- (void)drawRect:(NSRect)aRect;

- (void) prepareOpenGL;

- (void) thread_keys;

- (void) processKeys;

- (BOOL) acceptsFirstResponder; 

- (void) enableFullScreen;

- (void) setbrightness : (float) brght;

- (void) setCameraID: (unsigned int) idcam;

@end
