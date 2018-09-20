//
//  AudioBufferMixer.h
//  AudioChatClient
//
//  Created by  on 21/06/18.
//  Copyright © 2018 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#include <CoreServices/CoreServices.h>
#include <CoreAudio/CoreAudio.h>
#import "TPCircularBuffer.h"
#include <AudioToolbox/AudioToolbox.h>
#include <AudioUnit/AudioUnit.h>


//#import "AudioBufferWriter.h"

@interface AudioBufferMixer : NSObject
{

    
    TPCircularBuffer _circularBuffer;
    

    
    BOOL auGraphStarted;
    
    AUGraph mGraph;
    AUNode outputNode;
    AUNode mixerNode;
    
    AudioUnit    mOutputUnit;
    AudioUnit mixer;
    
    UInt32 clientCount;
    
    AudioStreamBasicDescription mixerFormat;
    
    AudioStreamBasicDescription deviceFormat;
}
-(void)setupAUGraph;
-(void)StopAUGraph;
-(void)StartAUGraph;


-(void)PlayAudioData:(NSData *)data withTag:(long)tag;
-(void)SetMixerFormat:(AudioStreamBasicDescription)format;

@end
