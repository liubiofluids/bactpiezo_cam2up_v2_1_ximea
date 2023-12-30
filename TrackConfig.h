//
//  TrackConfig.h
//  bacttrack
//
//  Created by Bin Liu on 8/24/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern long long width;
extern long long height;
extern double thrshld;
extern double scandelay;
extern int areamin;
extern int areamax;
extern float darktar;
extern float darklow;
extern float darkfoc;
extern float fgeom;
extern float fblur;

@interface TrackConfig : NSObject {
	
	IBOutlet NSWindow *window;
    uint m_track_width;
    uint m_track_height;
    IBOutlet NSTextField *m_text_track_width;
    IBOutlet NSTextField *m_text_track_height;
    double m_threshold;
    IBOutlet NSTextField *m_text_threshold;
    IBOutlet NSMatrix *m_button_track_switch;
    IBOutlet NSTextField* m_text_delaytime;
    double m_scandelay;
    int m_areamin;
    int m_areamax;
    IBOutlet NSTextField* m_text_areamin;
    IBOutlet NSTextField* m_text_areamax;
    float m_dark1;
    float m_dark2;
    float m_dark3;
    float m_geom;
    float m_blur;
    IBOutlet NSTextField* m_text_dark1;
    IBOutlet NSTextField* m_text_dark2;
    IBOutlet NSTextField* m_text_dark3;
    IBOutlet NSTextField* m_text_geom;
    IBOutlet NSTextField* m_text_blur;
}

- (IBAction)applySetting:(id)sender; 
- (IBAction)undoSetting:(id)sender;

@end
