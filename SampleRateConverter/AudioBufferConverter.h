//
//  AudioBufferConverter.h
//  AVConverterAndPlayer
//
//  Created by  on 05/09/18.
//  Copyright © 2018 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include <CoreServices/CoreServices.h>
#include <CoreAudio/CoreAudio.h>
#import "TPCircularBuffer.h"
#include <AudioToolbox/AudioToolbox.h>
#include <AudioUnit/AudioUnit.h>
@interface AudioBufferConverter : NSObject
{
    TPCircularBuffer _circularBuffer;
    AudioConverterRef    fConverter;
    
    AudioConverterRef converterRef;
    
    AudioStreamBasicDescription    fDeviceFormat, fOutputFormat;
    
    AudioStreamBasicDescription    inputFormat, outputFormat;
}

-(void)convertBuffer:(AudioBufferList*)fAudioOutputBuffer;


-(void)initConverter:(AudioStreamBasicDescription)inFormat :(AudioStreamBasicDescription)outFormat;

-(void)SetInputFormatAndInitialize:(AudioStreamBasicDescription)input outSampleRate:(int)sampleRate;

- (NSData *)ConvertData:(NSData *)inAudio;



@end
