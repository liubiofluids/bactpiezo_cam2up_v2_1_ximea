//
//  CameraListController.h
//
//  Created by Bin Liu on 8/9/11.
//  Copyright 2011 New York University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QPreviewController.h"
#import "CameraList.h"
#import "XiCameraList.h"
#import "ImgTool.h"
#import "CameraTypes.h"
#import "fullscreenWindow.h"
#include <dc1394/dc1394.h>
#import "PhidgetStepperController.h"
#import "Queue.h"
#import "NSCvImage.h"
#import "PiezoController.h"
#include <memory.h>

#define times 0**(int*)



#ifndef NMAXCAM
#define NMAXCAM 3  //3 cameras max
#endif

extern NSDate* startdate;
extern dc1394_t * d; 
extern dc1394camera_list_t * list;
extern dc1394error_t err;
extern dc1394camera_t **camera;
extern dc1394video_frame_t *curr_frame;
extern dc1394video_frame_t **pcurr_frame;
extern XI_IMG **pxiframe;
extern XI_IMG *xiframe;

extern unsigned int* exposure_time;
extern unsigned int exposure_time0;
extern bool linkstatus;
extern bool flagtrack;
extern bool flagstage;
extern bool	flagframeupdated;
extern bool flagframecaptured;
extern bool flagrecorder;
extern bool flagcalibr;
extern bool flagfullscreen;
extern bool flagpositionupdated;
extern bool flagauto;
extern bool flag_stopped;
extern bool flag_focus;
extern float camera_frame_rate;
extern NSLock* stage_lock;
extern struct tms tms_buf;
extern clock_t start_time;
extern float elapsed_time;
extern int i;
extern unsigned int min_bytes, max_bytes;
extern unsigned int actual_bytes;
extern uint64_t total_bytes;
extern unsigned int width, height;
extern FILE* imagefile;
extern unsigned char* img_buffer;
extern unsigned char** pbuffer;

extern float unit_xlen;
extern float* m_brightness_multip;
extern float m_brightness_multip0;
extern camstats* camera_info;

extern NSString *imgName;
extern long long xcrd[1000000];
extern long long ycrd[1000000];
extern long long zcrd[1000000];
extern float zpiezo[1000000];
extern float vpiezo[1000000];
extern double time_i[1000000];
extern float area[1000000];
extern float level[1000000];
extern long long target_x;
extern long long target_y;
extern long long target_z;
extern float trace_x;
extern float trace_y;
extern float trace_z;
extern double thrshld;
extern int indx_folder;
extern float target_piezo;
extern float target_piezo_max;
extern float target_piezo_min;
extern float actual_piezo;
extern double curr_frame_time;
extern double *pcurr_frame_time;

extern long long data_counter;
extern double scandelay;
extern double slp_piezo;
extern bool flag_imgszupdted;
extern bool flag_capture;
extern float saverate;
extern int pserial[3];

@interface CameraListController : NSObject {
    
	IBOutlet id DispCamera;
	IBOutlet id m_preview_switch;
	IBOutlet id m_run_button;
	IBOutlet id m_track_switch;
	IBOutlet id m_control_swith;
    IBOutlet id m_text_resx;
    IBOutlet id m_text_resy;
	IBOutlet CameraList *m_camera_list;
    IBOutlet XiCameraList *xi_camera_list;
	IBOutlet QPreviewController *m_previewController;
    IBOutlet QPreviewController *m_previewController_mult;
    CameraType *m_camera_type;
    QPreviewController** ppreviewContr;
    
	NSTimer *ptrig_camera[NMAXCAM];
    bool pflagcall[NMAXCAM];
    bool pflagcamstatus[NMAXCAM];
    int pfrmnum[NMAXCAM];
    unsigned long int pcount[NMAXCAM];
    
	IplImage *m_imgraw; 
	IplImage *m_imgsav;
    IplImage *m_test;

	IBOutlet id mainWindow;
	IBOutlet id cameraModel;
	IBOutlet id cameraManuf;
	IBOutlet id pictureBox;
	IBOutlet id exposureSetLabel; 
	IBOutlet id exposureSetTrack;
	IBOutlet id exposureSetValue;
	IBOutlet id brightnessSetLabel; 
	IBOutlet id brightnessSetTrack;
	IBOutlet id brightnessSetValue;
    IBOutlet id iautocontrast;
    IBOutlet id icb_inverse;
	IBOutlet id previewControlBox;
    IBOutlet id stageControlBox;
    
	IBOutlet fullscreenWindow *viewWindow;
    IBOutlet fullscreenWindow *viewWindow_mult;
    fullscreenWindow **pview;
    
	IBOutlet NSMatrix *recorderSwitch;
    IBOutlet NSComboBox *cammodSwitch;
	
	NSMutableSet * keysPressed;
	IBOutlet PhidgetStepperController* m_stepper_1;
	IBOutlet PhidgetStepperController* m_stepper_2;
	IBOutlet PhidgetStepperController* m_stepper_3;
	IBOutlet PiezoController* piezo01; 
	
	NSString *imgName;
	IBOutlet NSTextField *m_text_imgname;
	NSString *imgPath;	
	IBOutlet NSTextField *m_text_imgpath;
	NSRect m_oldRect;
	int m_oldLevel;
	IBOutlet ImgTool* m_imgtoolbox;
	uint m_bufferSize;
	Queue *m_imgBuffer;
    Queue *pimgBuffer[NMAXCAM];
    uint m_track_width;
    uint m_track_height;
    uint m_track_width0;
    uint m_track_height0;
    uint m_track_width1;
    uint m_track_height1;
    float m_threshold;
    uint m_areamin;
    uint m_areamax;
    float m_dark1;
    float m_dark2;
    float m_dark3;
    uint m_camid;
    uint numcam;
    uint numcam_xi;
    uint numcam_tot;

    
    IBOutlet NSTextField* m_text_track_width;
    IBOutlet NSTextField* m_text_track_height;
    IBOutlet NSTextField* m_text_threshold;
    IBOutlet NSTextField* m_text_areamin;
    IBOutlet NSTextField* m_text_areamax;
    IBOutlet NSTextField* m_text_dark1;
    IBOutlet NSTextField* m_text_dark2;
    IBOutlet NSTextField* m_text_dark3;
    IBOutlet NSTextField* m_text_geom;
    IBOutlet NSTextField* m_text_blur;
    
    NSLock* m_lock_video;
    unsigned char* m_img_buffer;
    unsigned char** pimg_buffer;
    
    bool flagTargetLocked;
    float m_weightedArea;
    float m_weightedArea0;
    float m_graylevel;
    bool flagstill;
    double m_graylevelmax;
    NSLock* m_lock_piezo;
    float m_geom;
    float m_blur;
    bool flag_cam_stats;

}

- (IBAction)LinkCamera:(id)sender;
- (IBAction)SetCamera:(id)sender;
- (IBAction)SetTracker:(id)sender;
- (IBAction)CaptureVideo:(id)sender;
- (IBAction)TrackVideo:(id)sender;
- (IBAction)setExposure: (id)sender;
- (IBAction)setBrightness: (id)sender;
- (IBAction)autocontrastSelect:(id)sender;
- (IBAction)invertSelect:(id)sender;
- (IBAction)recorderSelected: (id)sender;
- (IBAction)recorderDeselected: (id)sender;
- (IBAction)manualSelected:(id)sender;
- (IBAction)manualDeselected:(id)sender;

- (IBAction)calibrSelected: (id)sender;
- (IBAction)calibrDeselected: (id)sender;
- (IBAction)selectCamera: (id) sender;

- (id)init;
- (void) thread_capture;
- (void) thread_track;
- (void) thread_record;
- (void)setPicture:(int)camera_id;
@end
