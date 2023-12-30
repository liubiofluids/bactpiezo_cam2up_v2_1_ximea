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
|				account image size changes.  It should also try to use the 
|				buffer supplied in the QCam_Frame.  This way, it can avoid a 
|				copy from the frame buffer to a temporary buffer each update.  
|				This slows down the preview considerably.
|
|==============================================================================
| dd/mon/yy  Author		Notes
|------------------------------------------------------------------------------
| 08/Oct/02  JonS		Original.
|==============================================================================
*/

#import "QPreviewView.h"
#import "Qframecopy.h"

#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>
#include <fstream>
#include <iostream>

using namespace std;

@implementation QPreviewView

- (void)importFrame: (unsigned char *)frame_buffer
{
	// We need to lock here as we don't want to be writing to the
	// buffer while we are drawing.
    


    [[self openGLContext] makeCurrentContext];
    
	// If our buffer has not been initialzied, then initiaze it.
    if( m_buffer == nil || flag_imgszupdted == TRUE)
    {
		// What an awful awful way to do things.  It is a similar idea on how
		// it is done in the Preview controller (see QPreviewController.mm
		// approx. line 65).  What we are doing here is ensuring that
		// our buffer will never be too small.
        m_bufferSize = width*height * 10 + 32;
        [m_lock lock];
        [plock[m_camid] lock];
        if (m_buffer && camera_info[m_camid].flag_capture){ //(m_buffer && flag_capture){
            NSLog(@"delete: m_buffer, %d", m_buffer);
            delete [] m_buffer;
        }
        if (camera_info[m_camid].flag_capture){
            m_buffer = new unsigned char[ m_bufferSize ];
        }
        [m_lock unlock];
        [plock[m_camid] unlock];
//		NSLog (@"m_buffer: %d\n", m_buffer);
		// Get our aligned buffer pointer for OpenGL.
		m_alignedBufferPtr = (unsigned char *)(((unsigned long) m_buffer >> 5) << 5);
        
		// This preview assums that the image size is never going to change.
		// Obviously, this is not practical, but is beyond the limited scope of
		// this example.
        m_imageSize = width*height;
/*		if(!flagfullscreen){
			m_width = width;
			m_height = height;
		}
 */
		// Create a new NSRect.
        NSRect newSize;
        
		// Initialzie it to the size of the image.
        newSize.origin.x = 0;
		if (flagfullscreen){
			newSize.origin.y=0;
		}
		else{
			newSize.origin.y = 31;
		}
        newSize.size.width = m_width;
        newSize.size.height = m_height;
//        NSLog(@"newsize: %f, %f", newSize.size.width, newSize.size.height);
		// Change the size of the view to match the size of the image.  This
		// is ok because the view is in a scroll view (via Interface Builder).
		// And happily, this is all handled by cocoa for us.
        flag_imgszupdted = FALSE;
        [self setFrame:newSize];
    }
    NSLog(@"buffer: %d, %d, %d", frame_buffer, m_alignedBufferPtr, camera_info[m_camid].flag_capture);
    
    if (camera_info[m_camid].flag_capture){
        NSLog(@"ICBInv: %d", [icb_inverse state]);
        if ([iautocontrast state] == NSOnState){ //*** autostrech the intensity of image for display
            FrameCopyMemToRGBXNorm(frame_buffer, m_alignedBufferPtr);
            NSLog(@"NormImage");
        }
        else{
            if (fabs(m_brghtnss-1.)<1E-3) {
                FrameCopyMemToRGBX( frame_buffer, m_alignedBufferPtr ); //**************** copy frame to buffer
            }
            else{
                FrameCopyMemToRGBXScaled( frame_buffer, m_alignedBufferPtr, m_brghtnss); //**************** copy frame to buffer
            }
        }
    }
    //	FrameSetTarget(m_alignedBufferPtr, floor(fmod(.5*m_width+target_x-actual_x+m_width, m_width)),floor(fmod(.5*m_height+target_y-actual_y+m_height, m_height)), target_a, m_width, m_height );
    
	[m_lock lock];
    [plock[m_camid] lock];
	// If this is not the first image, we must delete the previous texture.
    if( !m_first )
    {    
        GLuint dt = 1;
        glDeleteTextures(1, &dt);
    }
    
	// Do a whole bunch of OpenGL to load the image as a texture.
/*    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 1);
    glTexParameterf(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_PRIORITY, 0.0f);
    glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    
    glTexImage2D( GL_TEXTURE_RECTANGLE_EXT, 
                  0, 
                  GL_RGBA, 
                  m_width,
                  m_height, 
                  0, 
                  GL_BGRA, 
                  GL_UNSIGNED_INT_8_8_8_8_REV, 
                  m_alignedBufferPtr );
*/    
	// We have our first image.
    m_first = false;
	
	// And an image is loaded
    m_loaded = true;
	
/*	fstream of;
	
	of.open("tmpdat.txt", ios_base::out);
	
	for(unsigned int i=0; i<m_height; i++)
	{	for(unsigned int j=0; j<m_width; j++)
		{
			int bdata=*(m_alignedBufferPtr+4*(i*m_width+j));
			of<<bdata<<' ';
		}
		of<<endl;
	}

	of.close();
	
	std::cout<<"Bin Liu's test! "<<(Uint32)m_alignedBufferPtr<<endl;
	NSRunAlertPanel( @"Saved", 
					@"image saved",
					@"Quit", nil, nil );

*/
	
	// Unlock the lock as we have finished writing to the buffer.
    [m_lock unlock];
    [plock[m_camid] unlock];
	// Tell the view that we need to be updated.
//    [self setNeedsDisplay:true];
}

- (id)initWithFrame:(NSRect)frameRect
{
    
	flagfullscreen=NO;
    flag_monitor_keys=YES;
    // We have not loaded a new image into the buffer.
    m_loaded = false;
    m_first = true;
    m_buffer = nil;
    m_buffer_full = nil;
	// Set all of our data members to some initial value.
    m_imageSize = 0;
    m_bufferSize = 0;
    count_key=0;
	
    m_width=width;
	m_height=height;
	m_imageSize=width*height;
	
	m_moveCursor = [NSCursor openHandCursor];
	m_dragCursor = [NSCursor closedHandCursor];
    if (!m_keyboard_lock) {
        m_keyboard_lock=[[NSLock alloc] init];
    }
    if (!keysPressed) {
		keysPressed = [[NSMutableSet alloc] init];
	}
	// Initize our mutual exclusion lock.
/*	if(!m_lock){
		m_lock = [[NSLock alloc] init];
	}
*/
	m_imgResize = [ImgTool alloc];
    // Init pixel format attribs
    NSOpenGLPixelFormatAttribute attrs[] =
    {
		NSOpenGLPFAAccelerated,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFADoubleBuffer,
		(NSOpenGLPixelFormatAttribute)0
    };

	// Get pixel format from OpenGL
    NSOpenGLPixelFormat* pixFmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    if (!pixFmt)
    {
		NSRunAlertPanel( @"QCam Error", 
						 @"No pixel format -- exiting",
						 @"Quit", nil, nil );
		exit(1);
    }
	
        // Initialize our self with our parent class.  
        // This still looks really weird to me.
    self = [super initWithFrame:frameRect pixelFormat:pixFmt];
    
    if( !self )
    {
        NSRunAlertPanel( @"Error", 
						 @"Not able to initialize the preview view.",
						 @"Quit", nil, nil );
        exit(1);
    }
	
	// Make this the current context.
//    [[self openGLContext] makeCurrentContext];
    m_GLContext = [self openGLContext];
    [m_GLContext makeCurrentContext];	
    
	// Setup some basic OpenGL stuff

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glColor4f(1.0, 1.0, 1.0, 1.0);
    
    glEnable(GL_TEXTURE_RECTANGLE_EXT);
    	
    // Call for a redisplay
    [self setNeedsDisplay:true];
	
/*	[NSTimer scheduledTimerWithTimeInterval:0.03
                                     target:self
                                   selector:@selector(processKeys)
                                   userInfo:nil repeats:YES];
*/
    NSLog(@"qpreviewview");
        
    [NSThread detachNewThreadSelector: @selector(thread_keys) toTarget:self withObject:nil];
 
    return self;
}

// This is what draws our preview view.
- (void)drawRect:(NSRect)aRect
{
	static bool fullscreenenabled = NO;
	static unsigned char* buffer_frame=nil;
    NSLog(@"drawrect");
	if (flagfullscreen && !fullscreenenabled) {
		NSRect screenRect = [[NSScreen mainScreen] frame];
		
		m_width=screenRect.size.width;
		m_height=screenRect.size.height;
        NSLog(@"Enabling full screen: %ld",m_buffer_full );
        if (m_buffer_full!=nil){
            delete [] m_buffer_full;
            m_buffer_full=nil;
        }
        
        if (m_buffer_full==nil)
		{
			unsigned int n_buffer=m_width*m_height*10+32;
                NSLog(@"Width: %d", width);
            m_buffer_full=new unsigned char[n_buffer];
			if(buffer_frame==nil){
				buffer_frame=new unsigned char[width*height*10]; /* make buffer large enough [160108] */
                NSLog(@"Width: %d", width);
			}
			
			if(m_alignedBufferPtr){
				RGBXToFrame(m_alignedBufferPtr, buffer_frame);
				m_alignedBufferPtr_full = (unsigned char *)(((unsigned long) m_buffer_full >> 5) << 5);
			
				IplImage *img0 = [m_imgResize Array2IplImageGray:buffer_frame width: width height: height];
				IplImage *img1 = cvCreateImage( cvSize(m_width, m_height), img0->depth, img0->nChannels);
				cvResize(img0, img1);
                NSLog(@"buffer2: %d, %d, %d", img1->imageData, m_alignedBufferPtr_full, m_width);
				FrameCopyMemToRGBX( (unsigned char*) (img1->imageData), m_alignedBufferPtr_full, m_width*m_height);
				cvReleaseImage(&img0);
				cvReleaseImage(&img1);
			}
		}
		[self setFrame: screenRect];
//NSLog(@"screen: %f, %f, %d", screenRect.size.width, screenRect.size.height, (int)m_alignedBufferPtr);
		[self update];
		fullscreenenabled = YES;
	}
	else if(!flagfullscreen && fullscreenenabled){
		NSRect newRect;
		newRect.size=NSMakeSize((float)width0, (float)height0);
		newRect.origin=NSMakePoint(0., 31.);
		//m_width=width;
        m_width=width0;
		//m_height=height;
        m_height=height0;
		m_alignedBufferPtr = (unsigned char *)(((unsigned long) m_buffer >> 5) << 5);
		[self setFrame: newRect];
//		NSRect currRect=[self frame];
//NSLog(@"currs: %f, %f, %d", currRect.size.width, currRect.size.height, (int)m_alignedBufferPtr);
        if (m_buffer_full!=nil){
            delete [] m_buffer_full;
            m_buffer_full=nil;
        }
        
        if (m_buffer_full==nil)
        {
            unsigned int n_buffer=m_width*m_height*10+32;
            NSLog(@"Width: %d", width);
            m_buffer_full=new unsigned char[n_buffer];
            if(buffer_frame==nil){
                buffer_frame=new unsigned char[width*height*10]; /* make buffer large enough [160108] */
                NSLog(@"Width: %d", width);
            }
            
            if(m_alignedBufferPtr){
                RGBXToFrame(m_alignedBufferPtr, buffer_frame);
                m_alignedBufferPtr_full = (unsigned char *)(((unsigned long) m_buffer_full >> 5) << 5);
                
                IplImage *img0 = [m_imgResize Array2IplImageGray:buffer_frame width: width height: height];
                IplImage *img1 = cvCreateImage( cvSize(m_width, m_height), img0->depth, img0->nChannels);
                cvResize(img0, img1);
                NSLog(@"buffer3: %d, %d, %d", img1->imageData, m_alignedBufferPtr_full, m_width);
                FrameCopyMemToRGBX( (unsigned char*) (img1->imageData), m_alignedBufferPtr_full, m_width*m_height);
                cvReleaseImage(&img0);
                cvReleaseImage(&img1);
            }
        }
        
        /*if(m_alignedBufferPtr){
            RGBXToFrame(m_alignedBufferPtr, buffer_frame);
            m_alignedBufferPtr_full = (unsigned char *)(((unsigned long) m_buffer_full >> 5) << 5);
            
        
        IplImage *img0 = [m_imgResize Array2IplImageGray:buffer_frame width: width height: height];
        IplImage *img1 = cvCreateImage( cvSize(m_width, m_height), img0->depth, img0->nChannels);
        cvResize(img0, img1);
        NSLog(@"buffer3: %d, %d, %d", img1->imageData, m_alignedBufferPtr, m_width);

        FrameCopyMemToRGBX( (unsigned char*) (img1->imageData), m_alignedBufferPtr_full, m_width*m_height);
        cvReleaseImage(&img0);
        cvReleaseImage(&img1);
        
		if(buffer_frame){
            NSLog(@"free: buffer_frame, %d", buffer_frame);
			delete[] buffer_frame;
			buffer_frame=nil;
		}*/
//		[self update];
		fullscreenenabled = NO;
 
	}
	else if(flagfullscreen && fullscreenenabled && m_alignedBufferPtr)
	{
		if(buffer_frame==nil){
			buffer_frame=new unsigned char[width*height*10];
		}
		RGBXToFrame(m_alignedBufferPtr, buffer_frame);
		IplImage *img0 = [m_imgResize Array2IplImageGray:buffer_frame width: width height: height];
		IplImage *img1 = cvCreateImage( cvSize(m_width, m_height), img0->depth, img0->nChannels);
		cvResize(img0, img1);
        NSLog(@"buffer4: %d, %d", img1->imageData, m_alignedBufferPtr_full);
		FrameCopyMemToRGBX( (unsigned char*) (img1->imageData), m_alignedBufferPtr_full, m_width*m_height);
		cvReleaseImage(&img0);
		cvReleaseImage(&img1);

	}
    else if(m_alignedBufferPtr){
        if (m_width==width && m_height==height){
            m_alignedBufferPtr_full=m_alignedBufferPtr;
        }
        else{
            if (m_buffer_full==nil)
            {
                unsigned int n_buffer=m_width*m_height*10+32;
                NSLog(@"Width: %d", width);
                m_buffer_full=new unsigned char[n_buffer];
                m_alignedBufferPtr_full = (unsigned char *)(((unsigned long) m_buffer_full >> 5) << 5);
            }
            if(buffer_frame==nil){
                buffer_frame=new unsigned char[width*height*10];
                NSLog(@"Width2: %d", width);
            }
            RGBXToFrame(m_alignedBufferPtr, buffer_frame);
            IplImage *img0 = [m_imgResize Array2IplImageGray:buffer_frame width: width height: height];
            IplImage *img1 = cvCreateImage( cvSize(m_width, m_height), img0->depth, img0->nChannels);
            cvResize(img0, img1);
            NSLog(@"buffer5: %d, %d", img1->imageData, m_alignedBufferPtr_full);
            FrameCopyMemToRGBX( (unsigned char*) (img1->imageData), m_alignedBufferPtr_full, m_width*m_height);
            cvReleaseImage(&img0);
            cvReleaseImage(&img1);
        }
    }
 
	// Make sure that we have a loaded image.
    if( m_loaded )
    {
		// We want to try to grab to lock here.  If we are in the middle
		// of updating the preview buffer, we don't want to draw it to the
		// screen. So, either get exclusive access or wait.
        [m_lock lock];
        [plock[m_camid] lock];
        // Make this context current
//		[[self openGLContext] makeCurrentContext];
//		[m_GLContext makeCurrentContext];
		// Do a bunch of open gl texture stuff.
		glGenTextures( 1, &m_texture );
		glBindTexture(GL_TEXTURE_RECTANGLE_EXT, m_texture);

		
 /*     if(!flagfullscreen){
			glTexImage2D( GL_TEXTURE_RECTANGLE_EXT, 
					  0, 
					  GL_RGBA,
					  m_width,
					  m_height,
					  0,
					  GL_BGRA,
					  GL_UNSIGNED_INT_8_8_8_8_REV,
                      m_alignedBufferPtr_full );
		}
		else {*/
            NSLog(@"fullscreen: %d, %d, %ld", m_width, m_height,  m_alignedBufferPtr_full);
            glTexImage2D( GL_TEXTURE_RECTANGLE_EXT,
						 0, 
						 GL_RGBA,
						 m_width,
						 m_height,
						 0,
						 GL_BGRA,
						 GL_UNSIGNED_INT_8_8_8_8_REV,
                         m_alignedBufferPtr_full );
/*	}
*/
		
		// Tell open GL where are texture goes.	

//		Having memory leak here 
		glBegin(GL_QUADS);
			glTexCoord2f((float)m_width, 0.0f);
            glVertex2f(1.0f, 1.0f);
        
            glTexCoord2f((float)m_width, (float)m_height);
            glVertex2f(1.0f, -1.0f);
			
            glTexCoord2f(0.0f, (float)m_height);
            glVertex2f(-1.0f, -1.0f);
        
            glTexCoord2f(0.0f, 0.0f);
            glVertex2f(-1.0f, 1.0f);
		glEnd();
//		Memory leak end here  
		
		glDeleteTextures(1, &m_texture);

        // Swap buffer to screen
//        [[self openGLContext] flushBuffer];
		[m_GLContext flushBuffer];
		// And we have finished updating, so release the lock.
        [m_lock unlock];
		[plock[m_camid] unlock];
//		[self clearGLContext];
    }


}

// This needs to be implemented from our parent open gl view.
- (void)update  // moved or resized
{
    NSRect rect;
	
	if(!flagfullscreen){
		rect = [self visibleRect];
	}
	else {
		rect = [[NSScreen mainScreen] frame];
	}

	
	float x = rect.origin.x;
	float y = rect.origin.y;
	NSLog( @"X: %f Y: %f W: %f H: %f", x, y, rect.size.width, rect.size.height );
    [super update];
	
//    [[self openGLContext] makeCurrentContext];
//    [[self openGLContext] update];
	[m_GLContext update]; 
	
//    rect = [self bounds];
	
    glViewport((int)-x, (int)-y, (int) rect.size.width, (int) rect.size.height);
	
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity(); 
	
    [self setNeedsDisplay:true];    
}

// This needs to be implemented from our parent open gl view.
- (void)reshape	// scrolled, moved or resized
{    
    NSRect rect;
	
	if(!flagfullscreen){
		rect = [self visibleRect];
	}
	else {
		rect = [[NSScreen mainScreen] frame];		
	}
	
	long x = rect.origin.x;
	long y = rect.origin.y;
        
//    [super reshape];
	
//    [[self openGLContext] makeCurrentContext];
//    [[self openGLContext] update];
	
//    rect = [self bounds];
	
//	NSLog( @"X: %li Y: %li W: %f H: %f", x, y, rect.size.width, rect.size.height );
	
    glViewport(-x, -y, rect.size.width, rect.size.height);
	
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
	
    [self setNeedsDisplay:true];    
}

- (void) prepareOpenGL
{
	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval]; // set to vbl sync
}

- (void) enableFullScreen
{
	
	flagfullscreen=YES;

}

- (void) mouseDown:(NSEvent *)theEvent
{
	
		if ([theEvent clickCount] > 1 && flagfullscreen==NO) {
			NSLog(@"double clicked"); 
			[self enableFullScreen];
		}
		else if([theEvent clickCount] > 1 && flagfullscreen==YES){
			flagfullscreen=NO;
		}

		else {
			NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
			old_x=(int)curPoint.x; old_y=m_height-curPoint.y;
			if (old_x>m_width) {
				old_x=m_width;
			}
			if (old_y>m_height) {
				old_y=m_height;
			}
            if(flagauto){
                [trace_lock lock];
                flag_tracelocked=TRUE;
                trace_x=(float)curPoint.x;
                trace_y=(float)curPoint.y;
                NSLog(@"trace locked: %f, %f", trace_x, trace_y);
                [trace_lock unlock];
            }
		}
}

- (void) mouseDragged: (NSEvent *)theEvent
{
	if(flagstage && !flagauto){
		NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		long curr_x=curPoint.x; long curr_y=m_height-curPoint.y;
        [stage_lock lock];
		target_x=actual_x-(int)((unit_xlen*width/width0)*(curr_x-old_x)); //minus in front of (int) for upright
		target_y=actual_y-(int)((unit_xlen*width/width0)*(curr_y-old_y));
        [stage_lock unlock];
	
	NSLog(@"Mouse Dragged Down: %d, %d, %d\n", (int)old_y, (int)curr_y, (int)target_y);
		old_x=curr_x; old_y=curr_y;

	if (target_x>m_width) {
//		target_x=m_width;
	}
	if (target_y>m_height) {
//		target_y=m_height;
	}
	}
}

- (void) mouseUp: (NSEvent *)theEvent
{
//	target_x=actual_x; target_y=actual_y;
	//	NSLog(@"Mouse Dragged Down\n");
}

- (void)keyDown:(NSEvent *) theEvent {
	NSLog(@"key down");
    NSNumber * keyHit = [NSNumber numberWithUnsignedInt:
						 [[theEvent characters] characterAtIndex:0]];
	NSLog (@"keyhit: %d\n", [keyHit unsignedIntValue]);
    [m_keyboard_lock lock];
	switch ([keyHit unsignedIntValue]) {
		case NSUpArrowFunctionKey:
		case NSDownArrowFunctionKey:
		case NSRightArrowFunctionKey:
		case NSLeftArrowFunctionKey:
        case '[':
        case ']':
        case 't':
        case 's':
		case ' ':
        case 'q':
        case 'w':
			[keysPressed addObject:keyHit];
            count_key++;
			break;
		case 27:
			NSLog(@"Excape\n");
			flagfullscreen=NO;
			break;
		default:
			break;
	}
    [m_keyboard_lock unlock];
}

- (void)keyUp:(NSEvent *)theEvent {
	NSNumber * keyReleased = [NSNumber numberWithUnsignedInt:
							  [[theEvent characters] characterAtIndex:0]];
    NSLog (@"keyreleased: %d\n", [keyReleased unsignedIntValue]);
    [m_keyboard_lock lock];
	switch ([keyReleased unsignedIntValue]) {
		case NSUpArrowFunctionKey:
		case NSDownArrowFunctionKey:
		case NSRightArrowFunctionKey:
		case NSLeftArrowFunctionKey:
        case '[':
        case ']':
		case 't':
        case 's':
        case ' ':
        case 'q':
        case 'w':
			[keysPressed removeObject:keyReleased];
            count_key--;
			break;
		default:
			break;
	}
    [m_keyboard_lock unlock];
}

- (void) thread_keys {
    while (flag_monitor_keys) {
        [m_keyboard_lock lock];
        [self processKeys];
        [m_keyboard_lock unlock];
        usleep(30000);
    }
}

- (void)processKeys {
//    NSLog(@"keynum: %d, %lld, %d", self, count_key, [keysPressed count]);
	if ([keysPressed count] != 0 && flagstage) {
  /*      if(count_key>30){
            count_key=0;
            [keysPressed removeAllObjects];
            return;
        }
   */
    //    NSLog(@"key count: %lld, %lu", count_key, (unsigned long)[keysPressed count]);

		NSEnumerator * enumerator = [keysPressed objectEnumerator];
		NSNumber * keyHit;
		/* process all keys of interest that are held down */
		while (keyHit = [enumerator nextObject]) {
			switch ([keyHit unsignedIntValue]) {
				case NSUpArrowFunctionKey:
					/* Your Up Arrow handling code */
					NSLog(@"Up Arrow");
					target_y=actual_y-10; //minus for upright
					break;
				case NSDownArrowFunctionKey:
					/* Your Down Arrow handling code */
					NSLog(@"Down Arrow\n");
					target_y=actual_y+10; //plus for upright
                    break;
				case NSRightArrowFunctionKey:
					/* Your Right Arrow handling code */
					NSLog(@"Right Arrow\n");
                    target_x=actual_x+10; //plus for upright
					break;
				case NSLeftArrowFunctionKey:
					/* Your Left Arrow handling code */
					NSLog(@"Left Arrow\n");
					target_x=actual_x-10; //minus for upright
                    break;
				case 32:
					/* Your Space Bar handling code */
					NSLog(@"Space bar\n");
                    
                case 91:
                    /* Move up */
					NSLog(@"Move up\n");
                    target_z=actual_z+(int)(unit_zlen);
					break;
                case 93:
                    NSLog(@"Move Down\n");
                    target_z=actual_z-(int)(unit_zlen);
					break;
                case 113: //q
                    if ([piezo_lock tryLock])
                    {    target_piezo=target_piezo+0.02; // zzz increment of Z position
                        NSLog(@"actual_z:%f", actual_piezo);
                        [piezo_lock unlock];
                    }
                    break;
                case 119: //w
                    if ([piezo_lock tryLock])
                    {    target_piezo=target_piezo-0.05;
                         NSLog(@"actual_z:%f", actual_piezo);
                        [piezo_lock unlock];
                    }
                    break;
                case 't':
                    flagauto=TRUE;
                    [m_button_track_switch setState:1 atRow:0 column:0];
//                    NSLog(@"track status %d, %d, %d", m_button_track_switch, flagauto, [m_button_track_switch intValue]);
                    break;
                case 's':
                    flagauto=FALSE;
                    [m_button_track_switch setState:1 atRow:1 column:0];
                    NSLog(@"track status %d, %d", flagauto, [m_button_track_auto isHighlighted]);
                    break; 
			}
/*			NSLog(@"target z: %d\n", target_z);
                NSLog(@"motor id: %d, %d, %d", [m_stepper_1 idAxis], [m_stepper_2 idAxis], [m_stepper_3 idAxis]);
			if ([m_stepper_1 idAxis]==3){
				[m_stepper_1 updatePosition: target_z];
			}
			else if ([m_stepper_2 idAxis]==3){
				[m_stepper_2 updatePosition: target_z];
			}
			else if ([m_stepper_3 idAxis]==3){
				[m_stepper_3 updatePosition: target_z];
			}	
			else {
				
			}
*/
		}
        if(count_key!=(unsigned long)[keysPressed count] && [keysPressed count]>10){
            count_key=0;
            [keysPressed removeAllObjects];
        }
		/* ask for a redraw at the next opportune time */
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)acceptsFirstResponder {
	return YES;
}


/*- (void) resetCursorRects {
	static bool dragged=YES;
	[super resetCursorRects];
	if(dragged){
		[self addCursorRect: [self bounds] cursor: m_moveCursor];
		dragged=NO;
	}
	else{
		[self addCursorRect: [self bounds] cursor: m_moveCursor];
		dragged=YES;
	}
}
 */

- (void) setbrightness : (float) brght {
    m_brghtnss=brght;
}

- (void) setCameraID:(unsigned int)idcam {
    m_camid=idcam;
}
@end