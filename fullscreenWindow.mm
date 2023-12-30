//
//  fullscreenWindow.m
//  bacttrack
//
//  Created by Bin Liu on 9/25/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import "fullscreenWindow.h"


@implementation fullscreenWindow

- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen
{
	//return the unaltered frame, or do some other interesting things
	return frameRect;
}

@end
