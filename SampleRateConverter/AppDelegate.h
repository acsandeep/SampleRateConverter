//
//  AppDelegate.h
//  SampleRateConverter
//
//  Created by  on 18/09/18.
//  Copyright © 2018 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>


#import "AudioBufferMixer.h"

#import "AudioBufferConverter.h"
@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    AVCaptureSession            *captureSession;
    AVCaptureDeviceInput        *captureAudioDeviceInput;
    AVCaptureAudioDataOutput    *captureAudioDataOutput;
    
    IBOutlet id _sampleTxt;
    IBOutlet id outsampleTxt;
    IBOutlet id preview;
    IBOutlet id mixerChk;
    IBOutlet id converterChk;
    
    AudioBufferMixer* bufferMixer;
    BOOL _startMixerPlayer;
    BOOL wantMixer;
    
    
    AudioBufferConverter* audioConverter;
    BOOL _startConverterPlayer;
    BOOL wantConverter;
}

-(IBAction)RecordAndPlay:(id)sender;
-(IBAction)Stop:(id)sender;
@end

