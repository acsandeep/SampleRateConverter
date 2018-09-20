//
//  AudioBufferMixer.m
//  AudioChatClient
//
//  Created by  on 21/06/18.
//  Copyright © 2018 . All rights reserved.
//

#import "AudioBufferMixer.h"
#import "AppDelegate.h"

@implementation AudioBufferMixer


static OSStatus renderInput(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{

    AudioBufferMixer *output = (__bridge AudioBufferMixer*)inRefCon;
    
    TPCircularBuffer *circularBuffer;
   // if(inBusNumber == 0)
        circularBuffer= [output outputShouldUseCircularBuffer];
    
    int32_t bytesToCopy = ioData->mBuffers[0].mDataByteSize;
    Byte* outputBuffer = (Byte*)ioData->mBuffers[0].mData;
    //Just copying the buffer to right channel also
 //   ioData->mBuffers[1].mData =  ioData->mBuffers[0].mData;
    ////////////////////
    
    uint32_t availableBytes;
    Byte* sourceBuffer = (Byte*)TPCircularBufferTail(circularBuffer, &availableBytes);

    int32_t amount = MIN(bytesToCopy,availableBytes);
    memcpy(outputBuffer, sourceBuffer, amount);
    NSLog(@"Input callback bus number= %d  available Bytes = %d amount = %d", inBusNumber, availableBytes, amount);
    
    TPCircularBufferConsume(circularBuffer,amount);

    return noErr;
}


-(TPCircularBuffer *) outputShouldUseCircularBuffer
{
    return &_circularBuffer;
}

static OSStatus OutputGrabber (void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
   NSLog(@"Output Grabber");
    AudioBufferMixer *output = (__bridge AudioBufferMixer*)inRefCon;
    
    TPCircularBuffer *circularBuffer;
//    circularBuffer= [output outputShouldUseCircularBuffer];
//    int32_t bytesToCopy = ioData->mBuffers[0].mDataByteSize;
//    SInt16* outputBuffer = (SInt16*)ioData->mBuffers[0].mData;
//
//    uint32_t availableBytes;
//    SInt16* sourceBuffer = (SInt16*)TPCircularBufferTail(circularBuffer, &availableBytes);
//
//    int32_t amount = MIN(bytesToCopy,availableBytes);
//    memcpy(outputBuffer, sourceBuffer, amount);
//    NSLog(@"Input callback bus number= %d  available Bytes = %d amount = %d", inBusNumber, availableBytes, amount);
//    TPCircularBufferConsume(circularBuffer,amount);
    return noErr;
    
    

}


- (instancetype)init
{
    self = [super init];
    if (self) {
         [self circularBuffer:&_circularBuffer withSize:24576*10];
   
        clientCount = 1;
        NSLog(@"init");
    }
    return self;
}


-(void)StopAUGraph
{
    NSLog(@"Stop Audio Graph1");
    
  //  [bufferWriter StopWritingToFile];
    
    if(mGraph)
    {
        NSLog(@"Stop Audio Graph2");
        Boolean isRunning;
        AUGraphIsRunning(mGraph,&isRunning);
        while(isRunning)
        {
            AUGraphStop(mGraph);
            AUGraphIsRunning(mGraph,&isRunning);
        }
        
        AUGraphClearConnections (mGraph);
        
        AUGraphUninitialize(mGraph);
        AUGraphClose(mGraph);
        DisposeAUGraph(mGraph);
        mGraph=0;
    }
    
    if(mOutputUnit)
    {
        
        
        AudioOutputUnitStop(mixer);
        AudioUnitUninitialize(mixer);
        // CloseComponent(mixer);
        mixer=0;
        
        AudioOutputUnitStop(mOutputUnit);
        AudioUnitUninitialize(mOutputUnit);
        //CloseComponent(mOutputUnit);
        mOutputUnit=0;
    }
}

-(void)StartAUGraph
{
    
    NSLog(@"Starting Audio Graph");
     if(auGraphStarted)
        [self StopAUGraph];
    auGraphStarted = YES;
  // AudioOutputUnitStart(mixer);
 //   AudioOutputUnitStart(mOutputUnit);
    AUGraphStart(mGraph);
}

-(void)setupAUGraph
{
    
    NSLog(@"setupAUGraph 1");
    if(mGraph)
    {
        AUGraphStop(mGraph);
    }
    
    OSStatus result = noErr;
    result = NewAUGraph(&mGraph);
    result = AUGraphOpen(mGraph);
    
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_DefaultOutput;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    
    AudioComponentDescription mixer_desc;
    mixer_desc.componentType = kAudioUnitType_Mixer;
    mixer_desc.componentSubType = kAudioUnitSubType_3DMixer; //kAudioUnitSubType_SpatialMixer
    mixer_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    mixer_desc.componentFlags = 0;
    mixer_desc.componentFlagsMask = 0;
    
    result  = AUGraphAddNode(mGraph, &desc, &outputNode);
    result  = AUGraphAddNode(mGraph, &mixer_desc, &mixerNode);
    
    
    result = AUGraphConnectNodeInput(mGraph, mixerNode, 0, outputNode, 0 );
    
    
    result=AUGraphNodeInfo(mGraph, mixerNode, NULL, &mixer);
    result=AUGraphNodeInfo(mGraph, outputNode, NULL, &mOutputUnit);
    result=AUGraphNodeInfo(mGraph, mixerNode, NULL, &mOutputUnit);
    
    UInt32 startAtZero = 0;
    result = AudioUnitSetProperty(mOutputUnit,
                                  kAudioOutputUnitProperty_StartTimestampsAtZero,
                                  kAudioUnitScope_Global,
                                  0,
                                  &startAtZero,
                                  sizeof(startAtZero));
    
    
   UInt32 numbuses = 1;
    printf("set input bus count %u\n", (unsigned int)numbuses);
    result = AudioUnitSetProperty(    mixer,
                                  kAudioUnitProperty_ElementCount,
                                  kAudioUnitScope_Input,
                                  0,
                                  &numbuses,
                                  sizeof(UInt32) );
    
    
     numbuses = 1;
    printf("set output bus count %u\n", (unsigned int)numbuses);
    result = AudioUnitSetProperty(    mixer,
                                  kAudioUnitProperty_ElementCount,
                                  kAudioUnitScope_Output,
                                  0,
                                  &numbuses,
                                  sizeof(UInt32) );
    
 
   
    [self AddAudioBus:0];
    
 //   [self AddAudioBus:1];
    
    AudioUnitAddRenderNotify(mOutputUnit, OutputGrabber, (__bridge void *)self);
    UInt32 ipFormatSize=sizeof(mixerFormat);
    
    AudioUnitSetProperty(mOutputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &mixerFormat, ipFormatSize);
    
    AudioUnitSetProperty(mOutputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &mixerFormat, ipFormatSize);
    
    AUGraphInitialize(mGraph);
    
    [self StartAUGraph];

}


-(void)AddAudioBus:(UInt32)i
{
    NSLog(@"Adding Audio Bus = %d", i);
    AudioStreamBasicDescription fDeviceFormat = {0};
   fDeviceFormat  = mixerFormat;

    NSLog(@"mixer SampleRate = %f", fDeviceFormat.mSampleRate);
    NSLog(@"mixer num Channels = %d", fDeviceFormat.mChannelsPerFrame);
    NSLog(@"mixer mBits Per Channel = %d", fDeviceFormat.mBitsPerChannel);
    NSLog(@"mixer mBytes Per Frame = %d", fDeviceFormat.mBytesPerFrame);
    NSLog(@"mixer mBytes Per Packet = %d", fDeviceFormat.mBytesPerPacket);
    NSLog(@"mixer Frames Per Packet = %d", fDeviceFormat.mFramesPerPacket);
    NSLog(@"mixer Format Flags = %d", fDeviceFormat.mFormatFlags);
 
    AURenderCallbackStruct rcbs;
    rcbs.inputProc = &renderInput;
    rcbs.inputProcRefCon = (__bridge void*)self;
    OSStatus result;
    
    printf("set AUGraphSetNodeInputCallback\n");
    
    // set a callback for the specified node's specified input
    result = AUGraphSetNodeInputCallback(mGraph, mixerNode, i, &rcbs);
    if (result) { printf("AUGraphSetNodeInputCallback result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
    
    printf("set input bus %d, client kAudioUnitProperty_StreamFormat\n", (unsigned int)i);
    
    // set the input stream format, this is the format of the audio for mixer input
    result = AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, &fDeviceFormat, sizeof(fDeviceFormat));
    
    
    if (result) { printf("AudioUnitSetProperty Error %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }

    result = AudioUnitSetProperty (
                                            mixer,
                                            kAudioUnitProperty_ElementCount,
                                            kAudioUnitScope_Input, 0, &i, sizeof (i));
    if (result) { printf("AudioUnitSetProperty Error %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
    
    
    /*
    AudioStreamBasicDescription desc = {0};
    UInt32 size = sizeof(desc);
    result = AudioUnitGetProperty(  mixer,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  i,
                                  &desc,
                                  &size);
    // Initializes the structure to 0 to ensure there are no spurious values.
    memset (&desc, 0, sizeof (desc));
    result = AudioUnitSetProperty(  mixer,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  i,
                                  &desc,
                                  sizeof(desc));
result = AudioUnitSetProperty(     mixer,
                              kAudioUnitProperty_StreamFormat,
                              kAudioUnitScope_Output,
                              0,
                              &desc,
                              sizeof(desc));
    */
}

-(void)SetMixerFormat:(AudioStreamBasicDescription)format
{
    NSLog(@"Setting Mixer Fomat");
    mixerFormat  = format;
    return;

//    mixerFormat.mSampleRate = 44100;
//    mixerFormat.mFormatID = kAudioFormatLinearPCM;
//    mixerFormat.mFormatFlags =kAudioFormatFlagIsFloat|kAudioFormatFlagIsBigEndian;
//    mixerFormat.mBitsPerChannel = 32;
//    mixerFormat.mChannelsPerFrame = 1;
//    mixerFormat.mBytesPerFrame = 4;
//    mixerFormat.mFramesPerPacket = 1;
//    mixerFormat.mBytesPerPacket =4;
    
    
    
}




-(AudioStreamBasicDescription)getFormat
{
    AudioStreamBasicDescription fDeviceFormat;
    memset(&fDeviceFormat, 0, sizeof(AudioStreamBasicDescription));
    fDeviceFormat.mChannelsPerFrame = 2;
    
    fDeviceFormat.mFormatID = kAudioFormatLinearPCM;
    fDeviceFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
#if __BIG_ENDIAN__
    fDeviceFormat.mFormatFlags |= kAudioFormatFlagIsBigEndian;
#endif
    fDeviceFormat.mBitsPerChannel = sizeof(Float32) * 8;
    fDeviceFormat.mBytesPerFrame = fDeviceFormat.mBitsPerChannel / 8;
    fDeviceFormat.mFramesPerPacket = 1;
    fDeviceFormat.mBytesPerPacket = fDeviceFormat.mBytesPerFrame;
    return fDeviceFormat;
}

-(void)AddMixerAudioUnits:(AudioUnit*)getAU
{
    AudioUnitConnection connection;
    connection.sourceAudioUnit = *getAU;
    connection.sourceOutputNumber = 0;
    connection.destInputNumber = clientCount++;
    
    
    
    AudioUnitSetProperty (mixer,
                          kAudioUnitProperty_MakeConnection,
                          kAudioUnitScope_Input, 0,
                          &connection, sizeof(connection));
    AudioUnitInitialize(*getAU);
    AudioOutputUnitStart(*getAU);
}



-(void)PlayAudioData:(NSData *)data withTag:(long)tag
{
   // NSLog(@"Data to play = %d", [data length]);
    if(data.length > 0)
    {
        UInt32 len = [data length]; //2048
        
        Byte* soundData = (Byte*)malloc(len);
        memcpy(soundData, [data bytes], len);
        
        
        
//a test to insert silence .....
//        int count,i;
//            for (i=0; i < len ; i++)
//                soundData[i]=0;//sourceBuffer[i];
        
        
        
        
        
        if(soundData)
        {
            AudioBufferList *theDataBuffer = (AudioBufferList*) malloc(sizeof(AudioBufferList)*1 );
            int i;
            for(i=0;i<1;i++)
            {theDataBuffer->mNumberBuffers = 1;
                
                theDataBuffer->mBuffers[i].mDataByteSize = len;
                theDataBuffer->mBuffers[i].mNumberChannels = 1;
                theDataBuffer->mBuffers[i].mData = soundData;
            }
            
            NSLog(@"Appending data to circular buffer = %d", len);
            [self appendDataToCircularBuffer:&_circularBuffer fromAudioBufferList:theDataBuffer];
        
        }
    }
}

-(void)ReadAudioBufferList:(AudioBufferList*)audioBuffer
{
    [self appendDataToCircularBuffer:&_circularBuffer fromAudioBufferList:audioBuffer];
}

-(void)circularBuffer:(TPCircularBuffer *)circularBuffer withSize:(int)size {
    TPCircularBufferInit(circularBuffer,size);
}

-(void)appendDataToCircularBuffer:(TPCircularBuffer*)circularBuffer
              fromAudioBufferList:(AudioBufferList*)audioBufferList {
    if(!TPCircularBufferProduceBytes(circularBuffer,
                                 audioBufferList->mBuffers[0].mData,
                                 audioBufferList->mBuffers[0].mDataByteSize))
    {
        NSLog(@"Error Appending audio data");
    }
}

-(void)freeCircularBuffer:(TPCircularBuffer *)circularBuffer {
    TPCircularBufferClear(circularBuffer);
    TPCircularBufferCleanup(circularBuffer);
}

@end
