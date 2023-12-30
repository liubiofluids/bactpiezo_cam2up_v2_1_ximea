//
//  CameraConfig.m
//  bacttrack
//
//  Created by Bin Liu on 8/12/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import "CameraConfig.h"


@implementation CameraConfig

- (id)init
{
    if (self = [super init])
    {
        // Initialization code here
        
    }
    return self;
}

- (void) awakeFromNib
{
    [m_text_resx setIntegerValue:width];
    [m_text_resy setIntegerValue:height];
    [m_text_saverate setStringValue:[NSString stringWithFormat:@"%.3f", saverate]];
}

- (IBAction)applySetting:(id)sender {
	imgName=[m_text_imgname stringValue];
	imgPath=[m_text_imgpath stringValue];
	imgName=[imgPath stringByAppendingString: imgName];
	NSLog(imgName, 1);
	[window orderOut: nil];
    width=[m_text_resx integerValue];
    height=[m_text_resy integerValue];
    saverate=[m_text_saverate floatValue];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
	[textbox_time setIntValue: exposure_time];

}

@end
