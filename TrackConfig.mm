//
//  TrackConfig.m
//  bacttrack
//
//  Created by Bin Liu on 8/24/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import "TrackConfig.h"


@implementation TrackConfig


- (id)init
{
    if (self = [super init])
    {
		// Initialization code here
		m_track_height=height;
        m_track_width=width;
        m_threshold=thrshld;
        m_scandelay=scandelay;
        m_areamin=areamin;
        m_areamax=areamax;
        m_dark1=darktar;
        m_dark2=darklow;
        m_dark3=darkfoc;
        m_geom=fgeom;
        m_blur=fblur;
	}
    return self;
}

- (void) awakeFromNib
{
    [m_text_track_height setIntValue: m_track_height];
    [m_text_track_width setIntValue: m_track_width];
    [m_text_threshold setStringValue: [NSString stringWithFormat:@"%.3f", m_threshold]];
    [m_text_delaytime setStringValue: [NSString stringWithFormat:@"%.3f", m_scandelay]];
    [m_text_areamin setIntValue: m_areamin];
    [m_text_areamax setIntValue: m_areamax];
    [m_text_dark1 setStringValue: [NSString stringWithFormat:@"%.3f", m_dark1]];
    [m_text_dark2 setStringValue: [NSString stringWithFormat:@"%.3f", m_dark2]];
    [m_text_dark3 setStringValue: [NSString stringWithFormat:@"%.3f", m_dark3]];
    [m_text_geom setStringValue: [NSString stringWithFormat:@"%.3f", m_geom]];
    [m_text_blur setStringValue: [NSString stringWithFormat:@"%.2f", m_blur]];
}

- (IBAction)applySetting:(id)sender {
    m_track_width=[m_text_track_width intValue];
    m_track_height=[m_text_track_height intValue];
    m_threshold=[m_text_threshold floatValue];
    m_scandelay=[m_text_delaytime floatValue];
    m_areamin=[m_text_areamin intValue];
    m_areamax=[m_text_areamax intValue];
    m_dark1=[m_text_dark1 floatValue];
    m_dark2=[m_text_dark2 floatValue];
    m_dark3=[m_text_dark3 floatValue];
    m_geom=[m_text_geom floatValue];
    scandelay=m_scandelay;
	[window orderOut: nil];
}

- (IBAction)undoSetting:(id)sender {
    [m_text_track_height setIntValue: m_track_height];
    [m_text_track_width setIntValue: m_track_width];
    [m_text_threshold setFloatValue: m_threshold];
    [m_text_delaytime setFloatValue: m_scandelay];
    [m_text_areamin setIntValue: m_areamin];
    [m_text_areamax setIntValue: m_areamax];
    [m_text_dark1 setFloatValue: m_dark1];
    [m_text_dark2 setFloatValue: m_dark2];
    [m_text_dark3 setFloatValue: m_dark3];
    [m_text_geom setFloatValue: m_geom];
	[window orderOut: nil];
}

@end
