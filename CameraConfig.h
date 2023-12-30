//
//  CameraConfig.h
//  bacttrack
//
//  Created by Bin Liu on 8/12/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern unsigned int exposure_time;
extern long long width;
extern long long height;
extern float saverate;

@interface CameraConfig : NSView {
    IBOutlet id textbox_time;
	IBOutlet NSWindow *window;
	NSString *imgName;
	IBOutlet NSTextField *m_text_imgname;
	NSString *imgPath;	
	IBOutlet NSTextField *m_text_imgpath;
    IBOutlet NSTextField *m_text_resx;
    IBOutlet NSTextField *m_text_resy;
    IBOutlet NSTextField *m_text_saverate;
}

- (IBAction)applySetting:(id)sender; 
@end
