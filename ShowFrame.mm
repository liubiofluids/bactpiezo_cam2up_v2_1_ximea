//
//  ShowFrame.m
//  bacttrack
//
//  Created by Bin Liu on 8/18/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import "ShowFrame.h"
extern bool flagstage;

@implementation ShowFrame

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
	NSString *sFrame = [NSString stringWithFormat:@"%.4f fps    stage: x = %d, y = %d, z = %d, tmp: %d", camera_frame_rate, (int)target_x, (int)target_y, (int)target_z, flagstage];
	NSPoint point = NSMakePoint(20, 10);
	NSMutableDictionary *font_attributes = [[NSMutableDictionary alloc] init];
	NSFont *font = [NSFont fontWithName:@"Verdana" size:12];
	[font_attributes setObject:font forKey:NSFontAttributeName];
	
	[sFrame drawAtPoint:point withAttributes:font_attributes];
	
	[font_attributes release];
	
}

- (void) setCameraID :(int)camera_id{
    m_camid=camera_id;
}

@end
