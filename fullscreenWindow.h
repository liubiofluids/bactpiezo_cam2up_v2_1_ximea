//
//  fullscreenWindow.h
//  bacttrack
//
//  Created by Bin Liu on 9/25/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface fullscreenWindow : NSWindow {

}

- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen; 

@end
