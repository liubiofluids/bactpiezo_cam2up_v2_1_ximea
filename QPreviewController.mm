//
//  QPreviewController.m
//  bacttrack
//
//  Created by Bin Liu on 8/12/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import "QPreviewController.h"


@implementation QPreviewController

/*- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}
*/

- (id) init {
    if (self = [super init]) {
		NSLog(@"preview controller");
        m_camid=0;
	}
    return self;
}

- (void)update
{
	[m_previewView setNeedsDisplay: YES];
	[m_showframe setNeedsDisplay:YES];
    NSLog(@"pbuffer: %d, %d, %d", m_camid, pbuffer[m_camid], self);
	if (pbuffer[m_camid]) {
		[m_previewView importFrame: pbuffer[m_camid]];
	}
}

- (void) setBrightness:(float)brght
{
    [m_previewView setbrightness:brght];
}

- (void) setCameraID:(unsigned int)idcam
{
    m_camid=idcam;
    [m_previewView setCameraID: idcam];
    NSLog(@"camera %d selected: %d", m_camid, self);
}

@end
