//
//  AppDelegate.m
//  SampleRateConverter
//
//  Created by  on 18/09/18.
//  Copyright © 2018 . All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    bufferMixer = [[AudioBufferMixer alloc] init];
    audioConverter = [[AudioBufferConverter alloc] init];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(NSDictionary*)GetInputDictonary
{
    NSString* inputDesc = @"44100;2;32;1;1;1";
    NSArray* input = [inputDesc  componentsSeparatedByString:@";"];
    
    NSDictionary* outputSettingsDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        
                                        [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey, [NSNumber numberWithInt:[[_sampleTxt stringValue] intValue]],AVSampleRateKey, /*Not Supported*/
                                        [NSNumber numberWithInt: [[input objectAtIndex:1] intValue]],AVNumberOfChannelsKey,
                                        //                     @(kAudioFormatLinearPCM), AVFormatIDKey,
                                        [NSNumber numberWithInt:[[input objectAtIndex:2] intValue]],AVLinearPCMBitDepthKey,
                                        [NSNumber numberWithBool:[[input objectAtIndex:3] intValue]],AVLinearPCMIsBigEndianKey,
                                        [NSNumber numberWithBool:[[input objectAtIndex:4] intValue]],AVLinearPCMIsFloatKey,
                                        [NSNumber numberWithBool:[[input objectAtIndex:5] intValue]],AVLinearPCMIsNonInterleaved,
                                        
                                        //                                        [NSNumber numberWithInt:AVAudioQualityMedium],
                                        //                                        AVEncoderAudioQualityKey,
                                        //                                        [NSNumber numberWithInt:16],
                                        //                                        AVEncoderBitRateKey,
                                        
                                        
                                        nil];
    return outputSettingsDict;
}

-(IBAction)initAVRecorder
{
    
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    captureSession = [[AVCaptureSession alloc] init];
    if (!captureSession) {
        return;
    }
    
    // Create and add a device input for the audio device to the session
    NSError *error = nil;
    captureAudioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (!captureAudioDeviceInput) {
        [[NSAlert alertWithError:error] runModal];
        return;
    }
    
    if ([captureSession canAddInput: captureAudioDeviceInput]) {
        [captureSession addInput:captureAudioDeviceInput];
    } else {
        return;
    }
    
    // Create and add a AVCaptureAudioDataOutput object to the session
    captureAudioDataOutput = [AVCaptureAudioDataOutput new];
    
    if (!captureAudioDataOutput) {
        return;
    }
    
    if ([captureSession canAddOutput:captureAudioDataOutput]) {
        [captureSession addOutput:captureAudioDataOutput];
    } else {
        return;
    }
    
    
    //Will Work if we comment this line  and comment
    // fDeviceFormat  = mixerFormat; this line of  AddAudioBus:(UInt32)i
    //in AudioBufferMixer.m
    
    //Not working with the following custom settings.
    
    captureAudioDataOutput.audioSettings = [self GetInputDictonary];
    
    NSLog(@"AVCaptureAudioDataOutput Audio Settings: %@", captureAudioDataOutput.audioSettings);
    
    // Create a serial dispatch queue and set it on the AVCaptureAudioDataOutput object
    dispatch_queue_t audioDataOutputQueue = dispatch_queue_create("AudioDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    if (!audioDataOutputQueue){
        return;
    }
    
    [captureAudioDataOutput setSampleBufferDelegate:(id)self queue:audioDataOutputQueue];
    //dispatch_release(audioDataOutputQueue);
    
    
    if([preview state])
    {
        AVCaptureAudioPreviewOutput* audioOutput = [[AVCaptureAudioPreviewOutput alloc] init];
        audioOutput.volume = 1.0;
        [captureSession addOutput:audioOutput];
    }
    wantMixer = [mixerChk state];
    wantConverter = [converterChk state];
    [captureSession startRunning];
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    AudioStreamBasicDescription asbd = *(CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer)));
    
    NSData* data;
    data = [self convertToData:sampleBuffer];
    
    if(wantMixer)
    {
        if(!_startMixerPlayer)
        {
            
            NSLog(@"Sample Rate = %f", asbd.mSampleRate);
            NSLog(@"Bits Per Channel = %d", asbd.mBitsPerChannel);
            NSLog(@"Bytes per frame = %d", asbd.mBytesPerFrame);
            NSLog(@"Bytes per packet = %d", asbd.mBytesPerPacket);
            NSLog(@"Frames per packet = %d", asbd.mFramesPerPacket);
            NSLog(@"Format Flags = %d", asbd.mFormatFlags);
            
            [bufferMixer SetMixerFormat:asbd];
            [bufferMixer setupAUGraph];
            _startMixerPlayer = YES;
        }
    }
    
    if(wantConverter)
    {
        if(!_startConverterPlayer)
        {
            
            NSLog(@"Sample Rate = %f", asbd.mSampleRate);
            NSLog(@"Bits Per Channel = %d", asbd.mBitsPerChannel);
            NSLog(@"Bytes per frame = %d", asbd.mBytesPerFrame);
            NSLog(@"Bytes per packet = %d", asbd.mBytesPerPacket);
            NSLog(@"Frames per packet = %d", asbd.mFramesPerPacket);
            NSLog(@"Format Flags = %d", asbd.mFormatFlags);
            
            
            [audioConverter SetInputFormatAndInitialize:asbd outSampleRate:[outsampleTxt intValue]];
            _startConverterPlayer = YES;
        }
    }
    
    if(wantConverter)
    {
        NSData* convertedData = [audioConverter ConvertData:data];
        if(convertedData)
            NSLog(@"Converter Data length = %d", [convertedData length]);
    }
    
    if(wantMixer)
    {
        [bufferMixer PlayAudioData:data withTag:[data length]];
    }
}

-(NSData*)convertToData:(CMSampleBufferRef)sampleBufferRef
{
    if (sampleBufferRef){
        CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBufferRef);
        const AudioStreamBasicDescription *sampleBufferASBD = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
        
        CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
        
        size_t length = CMBlockBufferGetDataLength(blockBufferRef);
        if(sampleBufferASBD->mChannelsPerFrame == 2)
            length = length/2;
        
        SInt16 buffer[length];
        CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, buffer);
        
        NSData * data = [[NSData alloc] initWithBytes:buffer length:length];
        return data;
    }
    return nil;
}

-(IBAction)RecordAndPlay:(id)sender
{
    [self initAVRecorder];
}

-(IBAction)Stop:(id)sender
{
    [captureSession stopRunning];
    if(wantMixer)
        [bufferMixer StopAUGraph];
    _startMixerPlayer = NO;
}
@end
