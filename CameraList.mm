//
//  CameraDisplay.m
//  bacttrack
//
//  Created by Bin Liu on 8/11/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import "CameraList.h"


@implementation CameraList

- (id)init{
    if (self = [super init]) {
        // Initialization code here.
		printf("initiating!\n");
		
		d = dc1394_new ();
		if (!d){
//			NSLog(@"d: %d\n", d);
			return self;
		}
		err=dc1394_camera_enumerate (d, &list);
		//DC1394_ERR_RTN(err,"Failed to enumerate cameras");
		num_camera=list->num;
		if (list->num == 0) {
//			NSLog(@"No cameras found!:\n", list->num);
			//			dc1394_log_error("No cameras found");
			return self;
		}
		else {
			printf("num: %d\n", list->num);
		}
		
        camera=new dc1394camera_t*[list->num];
        
        for(int i=0; i<list->num; i++){
            camera[i] = dc1394_camera_new (d, list->ids[i].guid);
            NSLog(@"Camera %d", i);
        }
		if (!camera) {

		}
		else{
		}
		
		dc1394_camera_free_list (list);
		
		
    }
	
    return self;
}

/*- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
	if(list->num>0){
		NSString *sVendor; //@"Hello, World!";		
		sVendor = [NSString stringWithUTF8String: (camera->vendor) ];
		
		NSPoint point = NSMakePoint(20, 40);
		NSMutableDictionary *font_attributes = [[NSMutableDictionary alloc] init];
		NSFont *font = [NSFont fontWithName:@"Futura-MediumItalic" size:14];
		[font_attributes setObject:font forKey:NSFontAttributeName];
	
		[sVendor drawAtPoint:point withAttributes:font_attributes];
		sVendor = [NSString stringWithUTF8String: (camera->model) ];
		point = NSMakePoint(20, 20);
		[sVendor drawAtPoint:point withAttributes:font_attributes];
		[font_attributes release];

	}
	else {
		NSString *sVendor = @"Camera not found!";		
		NSPoint point = NSMakePoint(0, 40);
		NSMutableDictionary *font_attributes = [[NSMutableDictionary alloc] init];
		NSFont *font = [NSFont fontWithName:@"Futura-MediumItalic" size:14];
		[font_attributes setObject:font forKey:NSFontAttributeName];
		
		[sVendor drawAtPoint:point withAttributes:font_attributes];

		[font_attributes release];
	}
}
*/

- (unsigned int) CameraNumber {
	return num_camera;
}
@end
