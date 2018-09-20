//
//  AudioBufferConverter.m
//  AVConverterAndPlayer
//
//  Created by  on 05/09/18.
//  Copyright © 2018 . All rights reserved.
//

#import "AudioBufferConverter.h"



@implementation AudioBufferConverter

OSStatus ConverterProc(AudioConverterRef inAudioConverter,
                                        UInt32* ioNumberDataPackets,
                                        AudioBufferList* ioData,
                                        AudioStreamPacketDescription** outDataPacketDescription,
                                        void* inUserData)
{
    OSStatus err = kAudioUnitErr_InvalidPropertyValue;
    
    NSLog(@"Converter Proc 1");
    
    AudioBufferConverter *output = (__bridge AudioBufferConverter*)inUserData;
    
    TPCircularBuffer *circularBuffer = [output outputShouldUseCircularBuffer];
    
    int32_t bytesToCopy = ioData->mBuffers[0].mDataByteSize;
    SInt16* outputBuffer = (SInt16*)ioData->mBuffers[0].mData;
    //Just copying the buffer to right channel also
    ioData->mBuffers[1].mData =  ioData->mBuffers[0].mData;
    ////////////////////
    NSLog(@"Converter Proc 2");
    uint32_t availableBytes;
    SInt16* sourceBuffer = (SInt16*)TPCircularBufferTail(circularBuffer, &availableBytes);
    
    int32_t amount = MIN(bytesToCopy,availableBytes);
    
    memcpy(outputBuffer, sourceBuffer, amount);
    
    TPCircularBufferConsume(circularBuffer,amount);
    
    ioData->mBuffers[1].mData =  ioData->mBuffers[0].mData;
    NSLog(@"Converter Proc 3");
    return noErr;
}


-(void)HandleConverterProc:(AudioConverterRef) inAudioConverter :
(UInt32*) ioNumberDataPackets :
(AudioBufferList*) ioData :
                           (AudioStreamPacketDescription**) outDataPacketDescription
{
    NSLog(@"HandleConverterProc");
}

-(TPCircularBuffer *) outputShouldUseCircularBuffer
{
    return &_circularBuffer;
}



- (instancetype)init
{
    self = [super init];
    if (self) {
         [self circularBuffer:&_circularBuffer withSize:24576*5];
    }
    return self;
}

-(void)StartConverting
{
    AudioConverterReset(fConverter);
}


-(void)StopConverting
{
    AudioConverterDispose(fConverter);
}

-(void)convertBuffer:(AudioBufferList*)fAudioOutputBuffer
{
    
    [self appendDataToCircularBuffer:&_circularBuffer fromAudioBufferList:fAudioOutputBuffer];
    
    AudioBufferList myBuffer = {0};
    OSStatus err = noErr;
    UInt32     numPackets = fAudioOutputBuffer->mBuffers[0].mDataByteSize /  fOutputFormat.mBytesPerPacket;
    
    
    AudioBuffer inputBuffer;
    inputBuffer.mNumberChannels = 1;
    inputBuffer.mDataByteSize = fAudioOutputBuffer->mBuffers[0].mDataByteSize;
    inputBuffer.mData = fAudioOutputBuffer->mBuffers[0].mData;
    
    // describe output data buffers into which we can receive data.
    AudioBufferList outputBufferList;
    outputBufferList.mNumberBuffers = 1;
    outputBufferList.mBuffers[0].mNumberChannels = 1;
    outputBufferList.mBuffers[0].mDataByteSize = fAudioOutputBuffer->mBuffers[0].mDataByteSize;
    outputBufferList.mBuffers[0].mData = fAudioOutputBuffer->mBuffers[0].mData;;
    
    // set output data packet size
    UInt32 outputDataPacketSize = fOutputFormat.mBytesPerPacket;
    
    err = AudioConverterFillComplexBuffer(fConverter,
                                          ConverterProc, &inputBuffer, &numPackets,
                                          &outputDataPacketSize, NULL);
    NSLog(@"num Packets = %d", numPackets);
    if(err != noErr)
    {
        
        
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
            NSLog(@"Error = %@", error);
        
        char formatID[5];
        *(UInt32 *)formatID = CFSwapInt32HostToBig(err);
        formatID[4] = '\0';
        fprintf(stderr, "AudioConverterFillComplexBuffer FAILED 5! %ld '%-4.4s'\n",(long)err, formatID);
        
        return ;
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
    TPCircularBufferProduceBytes(circularBuffer,
                                 audioBufferList->mBuffers[0].mData,
                                 audioBufferList->mBuffers[0].mDataByteSize);
}

-(void)freeCircularBuffer:(TPCircularBuffer *)circularBuffer {
    TPCircularBufferClear(circularBuffer);
    TPCircularBufferCleanup(circularBuffer);
}


//================================================
//================================================


-(void)initConverter:(AudioStreamBasicDescription)inFormat :(AudioStreamBasicDescription)outFormat
{
    OSStatus status = AudioConverterNew(&inFormat, &outFormat, &converterRef);
    if(status != noErr)
    {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"AudioConverterNew Error = %@", error);
    }
    else
    {
//        if (inFormat.mChannelsPerFrame != outFormat.mChannelsPerFrame)
//        {
//            // This should be as large as the number of output channels,
//            // each element specifies which input channel's data is routed to that output channel
//            SInt32 channelMap[] = { 0, 0 };
//            status = AudioConverterSetProperty(fConverter, kAudioConverterChannelMap, 2*sizeof(SInt32), channelMap);
//            if(status != noErr)
//            {
//                NSLog(@"AudioConverterSetProperty %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
//            }
//        }
    
//        if (inFormat.mSampleRate != outFormat.mSampleRate) {
//
//            UInt32 quality = kAudioConverterQuality_Max;
//            status = AudioConverterSetProperty(fConverter,
//                                            kAudioConverterSampleRateConverterQuality,
//                                            sizeof(UInt32),
//                                            &quality);
//            if(status != noErr)
//            {
//                NSLog(@"AudioConverterSetProperty 2 %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
//            }
//        }
    }
}

OSStatus inInputDataProc1(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData)
{
    ioData->mNumberBuffers = 1;
    AudioBufferList audioBufferList = *(AudioBufferList *)inUserData;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData = audioBufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = audioBufferList.mBuffers[0].mDataByteSize;
    
    *ioNumberDataPackets = audioBufferList.mBuffers[0].mDataByteSize;
    return  noErr;
}

//ConvertData
- (NSData *)ConvertData:(NSData *)inAudio
{
    NSMutableData *ddd = [inAudio mutableCopy];
    NSLog(@"in Data Length = %d", [ddd length]);

    AudioBufferList inAudioBufferList = {0};
    inAudioBufferList.mNumberBuffers = 1;
    inAudioBufferList.mBuffers[0].mNumberChannels = 1;
    inAudioBufferList.mBuffers[0].mDataByteSize = (UInt32)[ddd length];
    inAudioBufferList.mBuffers[0].mData = [ddd mutableBytes];
    
    uint32_t bufferSize = (UInt32)[inAudio length] ;
    
   // uint8_t *buffer ;//= (uint8_t *)malloc(bufferSize);
   // memset(buffer, 0, bufferSize);
   // AudioBufferList* outAudioBufferList;
   // outAudioBufferList = [self AllocateAudioBufferList:1 :1 :8000];
//    [self convertBuffer:&inAudioBufferList];
//    return nil;
    
    //kAudioConverterErr_InvalidOutputSize
    
    char szBuf[bufferSize];
    int  nSize = sizeof(szBuf);
    AudioBufferList outAudioBufferList;
    outAudioBufferList.mNumberBuffers              = 1;
    outAudioBufferList.mBuffers[0].mNumberChannels = 1;
    outAudioBufferList.mBuffers[0].mDataByteSize   = nSize;
    outAudioBufferList.mBuffers[0].mData           = szBuf;
 //   UInt32 outputDataPacketSize               = nSize;//2048;
    
    UInt32 ioOutputDataPacketSize= bufferSize;
    
    OSStatus ret = AudioConverterFillComplexBuffer(converterRef, inInputDataProc1, &inAudioBufferList, &ioOutputDataPacketSize, &outAudioBufferList, NULL) ;
    
    if(ret != noErr)
    {
        NSLog(@"Error in converting data %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil]);
    }
    else
    {
    NSData *data = [NSData dataWithBytes:outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
    
    if(data)
    NSLog(@"Converted Data = %d", [data length]);
         return data;
    }
//   free(buffer);
   
    return nil;
}

-(AudioBufferList*)AllocateAudioBufferList:(UInt32) numBuffers : (UInt32) channelsPerBuffer : (UInt32) bufferByteSize
{
    AudioBufferList    *list = (AudioBufferList*)calloc(1, sizeof(AudioBufferList) + numBuffers * sizeof(AudioBuffer));
    
    if(list != NULL)
    {
        list->mNumberBuffers = numBuffers;
        
        for (UInt32 i = 0; i < list->mNumberBuffers; i++)
        {
            list->mBuffers[i].mNumberChannels = channelsPerBuffer;
            list->mBuffers[i].mData = calloc (1, bufferByteSize);
            list->mBuffers[i].mDataByteSize = bufferByteSize;
        }
    }
    return list;
}

-(void)SetInputFormatAndInitialize:(AudioStreamBasicDescription)input outSampleRate:(int)sampleRate
{
    inputFormat = input;
    //memset((void *)&fOutputFormat, 0, sizeof(AudioStreamBasicDescription));
    AudioStreamBasicDescription output = {0};
    output.mSampleRate = sampleRate;
    output.mFormatID = kAudioFormatLinearPCM;
    output.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved | kAudioFormatFlagIsBigEndian;
    output.mBitsPerChannel = 32;
    output.mChannelsPerFrame = 1;
    output.mBytesPerFrame = 4;//sizeof(SInt16) * output.mChannelsPerFrame;
    output.mFramesPerPacket = 1;
    output.mBytesPerPacket = 4;//output.mBytesPerFrame * output.mFramesPerPacket;
    fOutputFormat = output;
    
    [self initConverter:input :output];
}
@end
