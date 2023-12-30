//
//  CameraConfig.h
//
//  Created by Bin Liu on 8/12/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CameraConfig : /* Specify a superclass (eg: NSObject or NSView) */ {
    IBOutlet id textbox_time;
}
- (IBAction)applySetting:(id)sender;
@end
