//
//  main.m
//  bacttrack
//
//  Created by Bin Liu on 8/9/11.
//  Copyright 2011 New York University. All rights reserved.
//
#include <stdio.h>
#include <stdint.h>
#include <dc1394/dc1394.h>
#include <stdlib.h>
#include <time.h>
#include <inttypes.h>
#include "AMSerialPort.h"
#include <Phidget22/phidget22.h>
#import "Queue.h"
#import "CameraList.h"
#import "XiCameraList.h"

#ifdef _WIN32
#define times 0**(int*)
struct tms {int a;};
#else
#include <sys/times.h>

#endif

FILE* imagefile;
NSString *imgName=@"frame%05d.jpg";
dc1394camera_t **camera; //support multiple cameras

HANDLE *hxicamera;

int grab_n_frames = 2000;
struct tms tms_buf;
clock_t start_time;
float elapsed_time;
int i;
unsigned int min_bytes, max_bytes;
unsigned int actual_bytes;
uint64_t total_bytes = 0;
long long width=640;
long long height=480;
long long width0=640;
long long height0=480;
float saverate=0.;
double scandelay=0.02;
long long actual_x=0;//320;
long long actual_y=0;//240;
long long actual_z=0;
long long actual_z0=0;
long long target_a=128;
long long target_x=0;//320;
long long target_y=0;//240;
long long target_z=0;
float actual_piezo;
float target_piezo;
float target_piezo_max=9.5;
float target_piezo_min=0.5;

float trace_x=320;
float trace_y=240;
float trace_z=0;
double thrshld=0.85;
int areamin=48;
int areamax=1024;
int stp_backlash=20;
int actual_depth=0;
int target_depth=0;
int stage_x;
int stage_y;
int stage_z;
int indx_folder=0;
float unit_xlen=.12; // .24 for earlier prior stage;
float unit_zlen=1.;
float darktar=0.78;
float darklow=0.45;
float darkfoc=0.76;
float fgeom=0.3;
float fblur=1.;

AMSerialPort *port;
long long xcrd[1000000];
long long ycrd[1000000];
long long zcrd[1000000];
float zpiezo[1000000];
float vpiezo[1000000];
double time_i[1000000];
float area[1000000];
float level[1000000];
double curr_frame_time;
double *pcurr_frame_time;
long long data_counter=0;

dc1394video_frame_t *curr_frame=nil;
dc1394video_frame_t **pcurr_frame;

XI_IMG *xiframe;
XI_IMG **pxiframe;

dc1394_t * d;
dc1394camera_list_t * list;
dc1394error_t err;
unsigned int* exposure_time;
unsigned int exposure_time0 = EXPSR0;
float camera_frame_rate=0;
//clock_t start_time;
//struct tms tms_buf;
unsigned char* img_buffer;
unsigned char** pbuffer;
//float trace_x, trace_y;
bool flagtrack;
bool flagstage;
bool flagframeupdated;
bool flagframecaptured;
bool flagpositionupdated=FALSE;
bool flagrecorder;
bool flagcalibr;
bool flagfullscreen;
bool flagauto=NO;
bool flag_stopped=TRUE;
bool flag_tracelocked=FALSE;
bool flag_focus=TRUE;
bool flag_imgszupdted=FALSE;
bool flag_capture;

camstats* camera_info;
int pserial[3];

/*CPhidgetStepperHandle* m_stepper_x;
CPhidgetStepperHandle* m_stepper_y;
CPhidgetStepperHandle* m_stepper_z;*/

int num_phidget_connected=0;

int ind_phidget[3];

double slp_piezo=0.5 ; //calibration on the vertical tracking
NSLock *m_lock;
NSLock **plock;
NSLock *phidget_lock;
NSLock *buffer_lock;
NSLock *stage_lock;
NSLock *trace_lock;
NSLock *piezo_lock;

bool linkstatus=FALSE;

float* m_brightness_multip;
float m_brightness_multip0=1.;

NSDate *startdate;

unsigned char *m_buffer;

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
    return NSApplicationMain(argc,  (const char **) argv);
}
