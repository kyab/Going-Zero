//
//  AudioEngine.m
//  MyPlaythrough
//
//  Created by kyab on 2017/05/15.
//  Copyright © 2017年 kyab. All rights reserved.
//

#import "AudioEngine.h"
#import <AudioToolbox/AudioToolbox.h>

#define OUTPUT_DEVICE @"Built-in Output"
//#define OUTPUT_DEVICE @"Soundflower (2ch)"
#define LOOPBACK_DEVICE @"Going Zero Device"
//#define LOOPBACK_DEVICE @"Background Music"


static OSStatus converterInputProc(AudioConverterRef inAudioConverter,
                                   UInt32 *ioNumberDataPackets,
                                   AudioBufferList *ioData,
                                   AudioStreamPacketDescription **outPacketDesc,
                                   void *inUserData)
{
    SRCContext *ctx = (SRCContext *)inUserData;

    UInt32 frames = MIN(*ioNumberDataPackets, ctx->inAccumFrames);
    if (frames == 0) {
        *ioNumberDataPackets = 0;
        return noErr;
    }

    ioData->mNumberBuffers = CHANNELS;

    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData = ctx->inAccumL;
    ioData->mBuffers[0].mDataByteSize = frames * sizeof(float);

    ioData->mBuffers[1].mNumberChannels = 1;
    ioData->mBuffers[1].mData = ctx->inAccumR;
    ioData->mBuffers[1].mDataByteSize = frames * sizeof(float);

    // 消費した分を前詰め
    memmove(ctx->inAccumL,
            ctx->inAccumL + frames,
            (ctx->inAccumFrames - frames) * sizeof(float));
    memmove(ctx->inAccumR,
            ctx->inAccumR + frames,
            (ctx->inAccumFrames - frames) * sizeof(float));

    ctx->inAccumFrames -= frames;
    *ioNumberDataPackets = frames;

    return noErr;
}


OSStatus MyRender(void *inRefCon,
                  AudioUnitRenderActionFlags *ioActionFlags,
                  const AudioTimeStamp      *inTimeStamp,
                  UInt32 inBusNumber,
                  UInt32 inNumberFrames,
                  AudioBufferList *ioData){
    AudioEngine *engine = (__bridge AudioEngine *)inRefCon;
    return [engine renderOutput:ioActionFlags inTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames ioData:ioData];
}

//notify to read
OSStatus MyInputCallback(void *inRefCon,
                    AudioUnitRenderActionFlags *ioActionFlags,
                    const AudioTimeStamp      *inTimeStamp,
                    UInt32 inBusNumber,
                    UInt32 inNumberFrames,
                    AudioBufferList *ioData){
    {
//                static UInt32 count = 0;
//                if ((count % 100) == 0){
//                    NSLog(@"LoopbackSide inputcallback inNumberFrames = %u", inNumberFrames);
//                }
//                count++;
    }
    
    AudioEngine *engine = (__bridge AudioEngine *)inRefCon;
    return [engine inputCallback:ioActionFlags inTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames /*ioData:ioData*/];
    
}

@implementation AudioEngine
- (id)init
{
    self = [super init];
    return self;
}

-(void)setRenderDelegate:(id<AudioEngineDelegate>)delegate{
    _delegate = delegate;
}

- (OSStatus) renderOutput:(AudioUnitRenderActionFlags *)ioActionFlags inTimeStamp:(const AudioTimeStamp *) inTimeStamp inBusNumber:(UInt32) inBusNumber inNumberFrames:(UInt32)inNumberFrames ioData:(AudioBufferList *)ioData{
    
    return [_delegate outCallback:ioActionFlags inTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames ioData:ioData];
}


- (OSStatus) inputCallback:(AudioUnitRenderActionFlags *)ioActionFlags inTimeStamp:(const AudioTimeStamp *) inTimeStamp inBusNumber:(UInt32) inBusNumber inNumberFrames:(UInt32)inNumberFrames /*ioData:(AudioBufferList *)ioData*/{

    static BOOL numFramesPrinted = NO;
    if (!numFramesPrinted){
        NSLog(@"First inCallback NumFrames = %d", inNumberFrames);
        numFramesPrinted = YES;
    }
    
    //call render to get buffer from audio input (GoingZero Device)
    AudioBufferList *inABL = (AudioBufferList *)malloc(sizeof(AudioBufferList) +  sizeof(AudioBuffer)); // for left + right
    
    inABL->mNumberBuffers = CHANNELS;
    inABL->mBuffers[0].mNumberChannels = 1;
    inABL->mBuffers[0].mData = _srcCtx.inAccumL + _srcCtx.inAccumFrames;
    inABL->mBuffers[0].mDataByteSize = inNumberFrames * sizeof(float);
    inABL->mBuffers[1].mNumberChannels = 2;
    inABL->mBuffers[1].mData = _srcCtx.inAccumR + _srcCtx.inAccumFrames;
    inABL->mBuffers[1].mDataByteSize = inNumberFrames * sizeof(float);
    
    OSStatus ret = AudioUnitRender(_inputUnit,
                                   ioActionFlags,
                                   inTimeStamp,
                                   inBusNumber,
                                   inNumberFrames,
                                   inABL
                               );
    
    free(inABL);
    
    if ( 0!=ret ){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed AudioUnitRender err=%d(%@), in inputCallback()", ret, [err description]);
        return ret;
        
        //https://forum.juce.com/t/missing-kaudiounitproperty-maximumframesperslice/9109
    }
    
    _srcCtx.inAccumFrames += inNumberFrames;
    
    //do ARC
    if (_srcCtx.inAccumFrames < ACCUM_FRAMES){
//        NSLog(@"Just Accumulating frames: added %u %d/%d",inNumberFrames, _srcCtx.inAccumFrames, ACCUM_FRAMES);
        return noErr;
    }
    
//    UInt32 preInAccumFrames = _srcCtx.inAccumFrames;
    
    UInt32 outFrames = ACCUM_FRAMES;
    AudioBufferList *outABL = (AudioBufferList *)malloc(sizeof(AudioBufferList) +  sizeof(AudioBuffer)); // for left + right
    outABL->mNumberBuffers = CHANNELS;
    outABL->mBuffers[0].mNumberChannels = 1;
    outABL->mBuffers[0].mData = _srcCtx.outL;
    outABL->mBuffers[0].mDataByteSize = outFrames * sizeof(float);
    outABL->mBuffers[1].mNumberChannels = 1;
    outABL->mBuffers[1].mData = _srcCtx.outR;
    outABL->mBuffers[1].mDataByteSize = outFrames * sizeof(float);
    
    ret = AudioConverterFillComplexBuffer(_srcCtx.converter,
                                          converterInputProc,
                                          &_srcCtx,
                                          &outFrames,
                                          outABL,
                                          NULL);
    if ( 0!=ret ){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed AudioConverterFillComplexBuffer err=%d(%@)", ret, [err description]);
        free(outABL);
        return ret;
    }

//    NSLog(@"Converted frames: %u -> %u. Still accumlated = %u", preInAccumFrames, outFrames, _srcCtx.inAccumFrames);
    
    [_delegate audioInCallback: outFrames bufferList: outABL];
    free(outABL);
    
    return noErr;
}

//
////actual read from input. should be called from delegate's inCallback
////called from delegate callback
//- (OSStatus) readFromInput:(AudioUnitRenderActionFlags *)ioActionFlags inTimeStamp:(const AudioTimeStamp *) inTimeStamp inBusNumber:(UInt32) inBusNumber inNumberFrames:(UInt32)inNumberFrames /*ioData:(AudioBufferList *)ioData*/{
//
//    OSStatus ret = AudioUnitRender(_inputUnit,
//                               ioActionFlags,
//                               inTimeStamp,
//                               inBusNumber,
//                               inNumberFrames,
//                               ioData
//                               );
//    if ( 0!=ret ){
//        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
//        NSLog(@"Failed AudioUnitRender err=%d(%@)", ret, [err description]);
//        return ret;
//        
//        //https://forum.juce.com/t/missing-kaudiounitproperty-maximumframesperslice/9109
//        
//    }
//    
//    return ret;
//}


-(BOOL)initialize{
    
    memset(&_srcCtx, 0, sizeof(_srcCtx));
    
    if (![self obtainPreOutputDevice]){
        return NO;
    }
    
    [self reverseSyncVolume];
    
    if (![self initializeOutput]){
        return NO;
    }
    
    if (![self changeOutputDevice]){
        return NO;
    }
    
    if (![self initializeInput]){
        return NO;
    }
    
    [self setupVolumeSync];
    
    
    return YES;
    
}


- (BOOL)initializeOutput{
    OSStatus ret = noErr;
    
    ret = NewAUGraph(&_graph);
    if (FAILED(ret)) {
        NSLog(@"failed to create AU Graph");
        return NO;
    }
    ret = AUGraphOpen(_graph);
    if (FAILED(ret)) {
        NSLog(@"failed to open AU Graph");
        return NO;
    }
    
    AudioComponentDescription cd;
    
    cd.componentType = kAudioUnitType_Output;
    cd.componentSubType = kAudioUnitSubType_HALOutput;
    cd.componentManufacturer = kAudioUnitManufacturer_Apple;
    cd.componentFlags = 0;
    cd.componentFlagsMask = 0;
    AUNode outNode;
    ret = AUGraphAddNode(_graph, &cd, &outNode);
    if (FAILED(ret)){
        NSLog(@"failed to AUGraphAddNode");
        return NO;
    }
    ret = AUGraphNodeInfo(_graph, outNode, NULL, &_outUnit);
    if (FAILED(ret)){
        NSLog(@"failed to AUGraphNodeInfo");
        return NO;
    }
    
    
    //set callback to first unit
    AURenderCallbackStruct callbackInfo;
    callbackInfo.inputProc = MyRender;
    callbackInfo.inputProcRefCon = (__bridge void * _Nullable)(self);
    ret = AUGraphSetNodeInputCallback(_graph, outNode, 0, &callbackInfo);
    if (FAILED(ret)){
        NSLog(@"failed to set callback for Output");
        return NO;
    }
    
    AudioStreamBasicDescription asbd = {0};
    UInt32 size = sizeof(asbd);
    asbd.mSampleRate = 44100.0;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
    asbd.mBytesPerPacket = 4;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerFrame = 4;
    asbd.mChannelsPerFrame = 2;
    asbd.mBitsPerChannel = 32;
    
    
    ret = AudioUnitSetProperty(_outUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd, size);
    if (FAILED(ret)){
        NSLog(@"failed to kAudioUnitProperty_StreamFormat for output(I)");
        return NO;
    }
    
    ret = AUGraphInitialize(_graph);
    if (FAILED(ret)){
        NSLog(@"failed to AUGraphInitialize");
        return NO;
    }
    
    return YES;
    
}


- (NSArray<NSNumber *> *)listSupportedSampleRatesForDevice:(AudioDeviceID)deviceID
{
    NSLog(@"Listing supported sample rates for device ID: %u", deviceID);
    OSStatus ret;
    UInt32 size = 0;

    AudioObjectPropertyAddress addr = {
        kAudioDevicePropertyAvailableNominalSampleRates,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain
    };

    // サイズ取得
    ret = AudioObjectGetPropertyDataSize(deviceID,
                                         &addr,
                                         0,
                                         NULL,
                                         &size);
    if (ret != noErr || size == 0) {
        NSLog(@"Failed to get sample rate list size (%d)", ret);
        return nil;
    }

    UInt32 count = size / sizeof(AudioValueRange);
    AudioValueRange *ranges = malloc(size);

    ret = AudioObjectGetPropertyData(deviceID,
                                     &addr,
                                     0,
                                     NULL,
                                     &size,
                                     ranges);
    if (ret != noErr) {
        NSLog(@"Failed to get sample rate list (%d)", ret);
        free(ranges);
        return nil;
    }
    
    NSLog(@"Found %u sample rate ranges", count);

    NSMutableArray<NSNumber *> *rates = [NSMutableArray array];

    for (UInt32 i = 0; i < count; i++) {
        AudioValueRange r = ranges[i];

        if (r.mMinimum == r.mMaximum) {
            // 離散値
            [rates addObject:@(r.mMinimum)];
        } else {
            // レンジ（代表的な値を追加）
            double min = r.mMinimum;
            double max = r.mMaximum;

            double commonRates[] = {
                8000, 16000, 22050,
                32000, 44100, 48000,
                88200, 96000, 192000
            };

            for (int j = 0; j < sizeof(commonRates)/sizeof(double); j++) {
                double sr = commonRates[j];
                if (sr >= min && sr <= max) {
                    [rates addObject:@(sr)];
                }
            }
        }
    }

    free(ranges);

    // 重複削除 & ソート
    NSOrderedSet *unique = [NSOrderedSet orderedSetWithArray:rates];
    return [[unique array] sortedArrayUsingSelector:@selector(compare:)];
}

- (Float64)getCurrentSampleRateForDevice:(AudioDeviceID)deviceID
{
    Float64 sampleRate = 0;
    UInt32 size = sizeof(sampleRate);

    AudioObjectPropertyAddress addr = {
        kAudioDevicePropertyNominalSampleRate,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain
    };

    OSStatus ret = AudioObjectGetPropertyData(deviceID,
                                              &addr,
                                              0,
                                              NULL,
                                              &size,
                                              &sampleRate);
    if (ret != noErr) {
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain
                                           code:ret
                                       userInfo:nil];
        NSLog(@"Failed to get current sample rate for device %u: %@",
              deviceID, err);
        return 0;
    }

    return sampleRate;
}


-(BOOL)initializeInput{
    OSStatus ret = noErr;
    
    AudioComponent component;
    AudioComponentDescription cd;
    cd.componentType = kAudioUnitType_Output;
    cd.componentSubType = kAudioUnitSubType_HALOutput;
    cd.componentManufacturer = kAudioUnitManufacturer_Apple;
    cd.componentFlags = 0;
    cd.componentFlagsMask = 0;
    component = AudioComponentFindNext(NULL, &cd);
    AudioComponentInstanceNew(component, &_inputUnit);
    ret = AudioUnitInitialize(_inputUnit);
    if (FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to get input AU. err=%d(%@)", ret, [err description]);
        return NO;
    }
    
    if(![self setInputDevice]) return NO;
    if(![self setInputFormat]) return NO;
    if(![self setInputCallback]) return NO;
    
    return YES;
}

-(BOOL)setupVolumeSync{
    
    /*
     Some devices support volume control only via master channel. (BGM)
     Some devices support volume control only via each channel.  (Built-In Output)
     Some devices support both of master or channels.
     */
    AudioDeviceID bgm = [self getDeviceForName:LOOPBACK_DEVICE];

    Float32 scalar = 0;
    UInt32 size = sizeof(Float32);
    
    AudioObjectPropertyAddress propAddress;
    propAddress.mSelector = kAudioDevicePropertyVolumeScalar;
    propAddress.mScope = kAudioObjectPropertyScopeOutput;
    propAddress.mElement = 0; //use 1 and 2 for build in output
    
    if (0!=(AudioObjectGetPropertyData(bgm, &propAddress, 0, NULL, &size, &scalar))){
        NSLog(@"failed to get volume");
        return NO;
        
    }
    
    NSLog(@"Volume(Scalar) for BGM = %f", scalar);
    
    OSStatus ret = AudioObjectAddPropertyListener(bgm,&propAddress, PropListenerProc, (__bridge void *)self);
    
    if (0!=ret){
        NSLog(@"Failed to set notification");
        return NO;
    }
    
    return YES;
    
}


OSStatus PropListenerProc( AudioObjectID                       inObjectID,
                          UInt32                              inNumberAddresses,
                          const AudioObjectPropertyAddress*   inAddresses,
                          void* __nullable                    inClientData){
    AudioEngine *s = (__bridge AudioEngine *)inClientData;
    return [s propListenerProc:inObjectID inNumberAddresses:inNumberAddresses inAddresses:inAddresses];
}

-(OSStatus)propListenerProc:(AudioObjectID)inObjectId inNumberAddresses:(UInt32)inNumberAddresses inAddresses:(const AudioObjectPropertyAddress *)inAddresses{

    NSLog(@"volume changed");
    [self syncVolume];
    return noErr;
    
}

-(BOOL)syncVolume{
    AudioDeviceID bgm = [self getDeviceForName:LOOPBACK_DEVICE];

    Float32 scalar = 0;
    UInt32 size = sizeof(Float32);

    AudioObjectPropertyAddress propAddress;
    propAddress.mSelector = kAudioDevicePropertyVolumeScalar;
    propAddress.mScope = kAudioObjectPropertyScopeOutput;
    propAddress.mElement = 0; //use 1 and 2 for build in output

    if (0!=(AudioObjectGetPropertyData(bgm, &propAddress, 0, NULL, &size, &scalar))){
        NSLog(@"failed to get volume");
        return NO;
    }
    
//    propAddress.mElement = 1;
    if (0!=(AudioObjectSetPropertyData(_preOutputDeviceID, &propAddress, 0, NULL, size, &scalar))){
        NSLog(@"failed to sync volume 1");
        return NO;
    }
    
//    propAddress.mElement = 2;
//    if (0!=(AudioObjectSetPropertyData(_preOutputDeviceID, &propAddress, 0, NULL, size, &scalar))){
//        NSLog(@"failed to sync volume 2");
//        return NO;
//    }
    
    NSLog(@"Sync vol OK");
    return YES;

}

-(BOOL)reverseSyncVolume{
    AudioDeviceID bgm = [self getDeviceForName:LOOPBACK_DEVICE];

    Float32 scalar = 0;
    UInt32 size = sizeof(Float32);

    AudioObjectPropertyAddress propAddress;
    propAddress.mSelector = kAudioDevicePropertyVolumeScalar;
    propAddress.mScope = kAudioObjectPropertyScopeOutput;
    propAddress.mElement = 0; //??use 1 and 2 for build in output

    if (0!=(AudioObjectGetPropertyData(_preOutputDeviceID, &propAddress, 0, NULL, &size, &scalar))){
        NSLog(@"failed to get volume");
        return NO;
    }
    
    propAddress.mElement = 0;
    if (0!=(AudioObjectSetPropertyData(bgm, &propAddress, 0, NULL, size, &scalar))){
        NSLog(@"failed to sync volume(reverse)");
        return NO;
    }
    
    NSLog(@"reverse Sync vol OK");
    return YES;

}



-(BOOL)changeOutputDevice{
    AudioDeviceID builtInOutput = _preOutputDeviceID;//[self getDeviceForName:OUTPUT_DEVICE];

    OSStatus ret = AudioUnitSetProperty(_outUnit,
                               kAudioOutputUnitProperty_CurrentDevice,
                               kAudioUnitScope_Global,
                               0,
                               &builtInOutput,
                               sizeof(AudioDeviceID));
    if(FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to set Device for Input = %d(%@)", ret, [err description]);
        return NO;
    }
    
    AudioObjectPropertyAddress propAddress;
    propAddress.mSelector = kAudioDevicePropertyBufferFrameSize;
    propAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propAddress.mElement = kAudioObjectPropertyElementMain;
    UInt32 frameSize = 32;
    ret = AudioObjectSetPropertyData(builtInOutput,
                                     &propAddress,0, NULL, sizeof(UInt32), &frameSize);
    if(FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to set Device for Output = %d(%@)", ret, [err description]);
        return NO;
    }
    
    return YES;
}

- (Boolean)setInputDevice{
    OSStatus ret = noErr;
    
    //we should enable input and disable output at first.. shit! see TN2091.
    {
        UInt32 enableIO = 1;
        ret = AudioUnitSetProperty(_inputUnit,
                                   kAudioOutputUnitProperty_EnableIO,
                                   kAudioUnitScope_Input,
                                   1,   //input element
                                   &enableIO,
                                   sizeof(enableIO));
        if(FAILED(ret)){
            NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
            NSLog(@"Failed to kAudioOutputUnitProperty_EnableIO=%d(%@)", ret, [err description]);
            return NO;
        }
        
        enableIO = 0;
        ret = AudioUnitSetProperty(_inputUnit,
                                   kAudioOutputUnitProperty_EnableIO,
                                   kAudioUnitScope_Output,
                                   0,
                                   &enableIO,
                                   sizeof(enableIO));
        if(FAILED(ret)){
            NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
            NSLog(@"Failed to kAudioOutputUnitProperty_EnableIO=%d(%@)", ret, [err description]);
            return NO;
        }
    }
    
    AudioDeviceID inDevID = [self getDeviceForName:LOOPBACK_DEVICE];
    NSArray *rates =  [self listSupportedSampleRatesForDevice:inDevID];
    NSLog(@"supported rates: %@", rates);
    NSLog(@"current rate: %.1f", [self getCurrentSampleRateForDevice:inDevID]);
    

    ret = AudioUnitSetProperty(_inputUnit,
                               kAudioOutputUnitProperty_CurrentDevice,
                               kAudioUnitScope_Global,
                               0,
                               &inDevID,
                               sizeof(AudioDeviceID));
    if(FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to set Device for Input = %d(%@)", ret, [err description]);
        return NO;
    }
    
    AudioObjectPropertyAddress propAddress;
    propAddress.mSelector = kAudioDevicePropertyBufferFrameSize;
    propAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propAddress.mElement = kAudioObjectPropertyElementMain;
    UInt32 frameSize = 32;
    ret = AudioObjectSetPropertyData(inDevID,
                                     &propAddress,0, NULL, sizeof(UInt32), &frameSize);
    if(FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to set frame size for Input = %d(%@)", ret, [err description]);
            return NO;
    }
    
    
    
    return YES;
}


-(Boolean)setInputFormat {
    
    AudioStreamBasicDescription asbd_in = {0};
    UInt32 size = sizeof(asbd_in);
    asbd_in.mSampleRate = 48000.0;     //TODO 44100と両方に対応
    asbd_in.mFormatID = kAudioFormatLinearPCM;
    asbd_in.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
    asbd_in.mBytesPerPacket = 4;
    asbd_in.mFramesPerPacket = 1;
    asbd_in.mBytesPerFrame = 4;
    asbd_in.mChannelsPerFrame = 2;
    asbd_in.mBitsPerChannel = 32;
    
    OSStatus ret = AudioUnitSetProperty(_inputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &asbd_in, size);
    if(FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to Set Format for Input side = %d(%@)", ret, [err description]);
        return NO;
    }
    
    
    AudioStreamBasicDescription asbd_out = {0};
    asbd_out.mSampleRate = 44100.0;
    asbd_out.mFormatID = kAudioFormatLinearPCM;
    asbd_out.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
    asbd_out.mBytesPerPacket = 4;
    asbd_out.mFramesPerPacket = 1;
    asbd_out.mBytesPerFrame = 4;
    asbd_out.mChannelsPerFrame = 2;
    asbd_out.mBitsPerChannel = 32;
    
    ret = AudioConverterNew(&asbd_in, &asbd_out, &_srcCtx.converter);
    if (FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to create AudioConverter = %d(%@)", ret, [err description]);
        return NO;
    }
    
    UInt32 quality = kAudioConverterQuality_Medium;
    ret = AudioConverterSetProperty(_srcCtx.converter,
                                    kAudioConverterSampleRateConverterQuality,
                                    sizeof(quality),
                                    &quality);
    if (FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to set AudioConverter quality = %d(%@)", ret, [err description]);
        return NO;
    }
    
    UInt32 prime = kConverterPrimeMethod_None;
    ret = AudioConverterSetProperty(_srcCtx.converter,
                                    kAudioConverterPrimeMethod,
                                    sizeof(prime),
                                    &prime);
    
    if (FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to set AudioConverter prime method = %d(%@)", ret, [err description]);
        return NO;
    }
    
    
    NSLog(@"Input side format set successfully.");
    
    return YES;
}


-(Boolean)setInputCallback{
    AURenderCallbackStruct callback;
    callback.inputProc = MyInputCallback;
    callback.inputProcRefCon = (__bridge void * _Nullable)(self);
    
    OSStatus ret = AudioUnitSetProperty(
                                        _inputUnit,
                                        kAudioOutputUnitProperty_SetInputCallback,
                                        kAudioUnitScope_Global,
                                        0,
                                        &callback,
                                        sizeof(callback));
    if(FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to Set Input side callback = %d(%@)", ret, [err description]);
        return NO;
    }
    
    return YES;
    
}

- (AudioDeviceID)getDeviceForName:(NSString *)devName{
    OSStatus ret = noErr;
    UInt32 propertySize = 0;
    UInt32 num = 0;
    AudioDeviceID result = -1;
    
    AudioObjectPropertyAddress propAddress;
    propAddress.mSelector = kAudioHardwarePropertyDevices;
    propAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propAddress.mElement = kAudioObjectPropertyElementMain;
    
    ret = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propAddress, 0, NULL, &propertySize);
    
    if(FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to get CoreAudio devices = %d(%@)", ret, [err description]);
        return -1;
    }
    num = propertySize / sizeof(AudioObjectID);
    
    AudioObjectID *objects = (AudioObjectID *)malloc(propertySize);
    ret = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propAddress, 0, NULL, &propertySize, objects);
    if(FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to get CoreAudio devices = %d(%@)", ret, [err description]);
        free(objects);
        return -1;
    }
    
    for (int i = 0 ; i < num ; i++){
        CFStringRef name = NULL;
        propAddress.mSelector = kAudioObjectPropertyName;
        UInt32 size = sizeof(CFStringRef);
        ret = AudioObjectGetPropertyData(objects[i], &propAddress, 0, NULL,
                                         &size, &name);
        if(FAILED(ret)){
            NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
            NSLog(@"Failed to Get Name = %d(%@)", ret, [err description]);
            free(objects);
            return -1;
        }
        
        NSLog(@"getDeviceForName(%@) dev : %@",devName, name);
        
        if (name != NULL){
            if (CFStringCompare(name, (CFStringRef)devName,kCFCompareCaseInsensitive) == kCFCompareEqualTo){
                NSLog(@"Found device for %@",devName);
                result = objects[i];
//                break;
            }
            CFRelease(name);
        }
        
    }
    if (-1 == result){
        NSLog(@"getDeviceForName(%@) failed.",devName);
    }
    
    free(objects);
    return result;
}



-(BOOL)startOutput{
    
    if (_bIsPlaying){
        return YES;
    }
    
    
    OSStatus ret = AUGraphStart(_graph);
    if (FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to get start input. err=%d(%@)", ret, [err description]);
        return NO;
    }
    _bIsPlaying = YES;
    return YES;
}

-(BOOL)stopOutput{
    _bIsPlaying = NO;
    OSStatus ret = AUGraphStop(_graph);
    if (FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to get start input. err=%d(%@)", ret, [err description]);
        return NO;
    }
    return YES;
    
}

-(BOOL)startInput{
    OSStatus ret = AudioOutputUnitStart(_inputUnit);
    if (FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to get start input. err=%d(%@)", ret, [err description]);
        return NO;
    }
    _bIsRecording = YES;
    return YES;
}

-(BOOL)stopInput{
    _bIsRecording = NO;
    AudioOutputUnitStop(_inputUnit);
    
    return YES;
}


-(BOOL)isPlaying{
    return _bIsPlaying;
}

-(BOOL)isRecording{
    return _bIsRecording;
}

-(BOOL)obtainPreOutputDevice{
    AudioObjectPropertyAddress propAddress;
    propAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
    propAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propAddress.mElement = kAudioObjectPropertyElementMain;
    
    UInt32 size = sizeof(_preOutputDeviceID);
    OSStatus ret = AudioObjectGetPropertyData(kAudioObjectSystemObject,&propAddress,
                                              0, NULL, &size, &_preOutputDeviceID);
    
    if (0 < ret){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to get Current output %d(%@)", ret, [err description]);
        return NO;
    }
    return YES;
}


//system output
-(BOOL)changeSystemOutputDeviceToBGM{
    
    AudioObjectPropertyAddress propAddress;
    propAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
    propAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propAddress.mElement = kAudioObjectPropertyElementMain;
    
    AudioDeviceID bgmOut = [self getDeviceForName:LOOPBACK_DEVICE];
    
    OSStatus ret = AudioObjectSetPropertyData(kAudioObjectSystemObject,
                                              &propAddress,
                                              0,
                                              NULL,
                                              sizeof(AudioObjectID),
                                              &bgmOut);
    if(0 < ret){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to set Default output for BGM = %d(%@)", ret, [err description]);
        return NO;
    }
    
    return YES;

}
-(BOOL)restoreSystemOutputDevice{
    
    if (!_preOutputDeviceID) return YES;
    
    AudioObjectPropertyAddress propAddress;
    propAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
    propAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propAddress.mElement = kAudioObjectPropertyElementMain;

    OSStatus ret = AudioObjectSetPropertyData(kAudioObjectSystemObject,
                                     &propAddress,
                                     0,
                                     NULL,
                                     sizeof(AudioObjectID),
                                     &_preOutputDeviceID);
    if(0 < ret){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to restore Default output for BGM = %d(%@)", ret, [err description]);
        return NO;
    }
    
//    propAddress.mSelector = kAudioHardwarePropertyDefaultSystemOutputDevice;
//    propAddress.mScope = kAudioObjectPropertyScopeGlobal;
//    propAddress.mElement = kAudioObjectPropertyElementMaster;
//
//    ret = AudioObjectSetPropertyData(kAudioObjectSystemObject,
//                                     &propAddress,
//                                     0,
//                                     NULL,
//                                     sizeof(AudioObjectID),
//                                     &_preOutputDeviceID);
//    if(0 < ret){
//        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
//        NSLog(@"Failed to restore Default system output for BGM = %d(%@)", ret, [err description]);
//        return NO;
//    }
    
    return YES;
}

-(NSArray *)listDevices:(BOOL)output{
    
    NSMutableArray *ar = [[NSMutableArray alloc] init];
    OSStatus ret = noErr;
    UInt32 propertySize = 0;
    UInt32 num = 0;
    
    AudioObjectPropertyAddress propAddress;
    propAddress.mSelector = kAudioHardwarePropertyDevices;
    propAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propAddress.mElement = kAudioObjectPropertyElementMain;
    
    ret = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propAddress, 0, NULL, &propertySize);
    
    if(FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to set Device for Input = %d(%@)", ret, [err description]);
        return nil;
    }
    num = propertySize / sizeof(AudioObjectID);
    
    AudioObjectID *objects = (AudioObjectID *)malloc(propertySize);
    ret = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propAddress, 0, NULL, &propertySize, objects);
    if(FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to set Device for Input = %d(%@)", ret, [err description]);
        free(objects);
        return nil;
    }
    
    for (int i = 0 ; i < num ; i++){
        CFStringRef name = NULL;
        propAddress.mSelector = kAudioObjectPropertyName;
        UInt32 size = sizeof(CFStringRef);
        ret = AudioObjectGetPropertyData(objects[i], &propAddress, 0, NULL,
                                         &size, &name);
        if(FAILED(ret)){
            NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
            NSLog(@"Failed to Get Name = %d(%@)", ret, [err description]);
            free(objects);
            return nil;
        }
        
        //Check input/output supported
        //kAudioDevicePropertyStreams AudioStreamID
        propAddress.mSelector = kAudioDevicePropertyStreams;
        if (output){
            propAddress.mScope = kAudioObjectPropertyScopeOutput;
        }else{
            propAddress.mScope = kAudioObjectPropertyScopeInput;
        }
        propAddress.mElement = kAudioObjectPropertyElementMain;
        ret = AudioObjectGetPropertyDataSize(objects[i], &propAddress, 0, NULL, &propertySize);
        int num2 = propertySize / sizeof(AudioStreamID);
        if (num2 > 0 ){
            [ar addObject:(__bridge NSString *)name];
        }

        CFRelease(name);
        
    }
    free(objects);
    return [NSArray arrayWithArray:ar];
   
}

-(BOOL)changeInputDeviceTo:(NSString *)devName{
    
    AudioDeviceID devID = [self getDeviceForName:devName];
    if (devID == -1) {
        NSLog(@"Could not get device : %@", devName);
        return NO;
    }
    
    OSStatus ret = AudioUnitSetProperty(_inputUnit,
                               kAudioOutputUnitProperty_CurrentDevice,
                               kAudioUnitScope_Global,
                               0,
                               &devID,
                               sizeof(AudioDeviceID));
    if(FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to set Device for Input = %d(%@)", ret, [err description]);
        return NO;
    }
    
    AudioObjectPropertyAddress propAddress;
    propAddress.mSelector = kAudioDevicePropertyBufferFrameSize;
    propAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propAddress.mElement = kAudioObjectPropertyElementMain;
    UInt32 frameSize = 32;
    ret = AudioObjectSetPropertyData(devID,
                                     &propAddress,0, NULL, sizeof(UInt32), &frameSize);
    if(FAILED(ret)){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to set Device for Input = %d(%@)", ret, [err description]);
        return NO;
    }
    
    
    return YES;
    
}
//
//-(BOOL)testAirPlay{
//    
//    //cant support AirPlay from 10.11!!!
//    //Apple dont allow me to enumurate AirPlay Devices,
//    //So it cant be settable as HAL Unit's kAudioOutputUnitProperty_CurrentDevice, nor System's Default Output Device.
//    // Suspecting iTunes uses some magic. Could not find any application that does magic to allow Output devices to AirPlay devices.
//    // Bug : https://forums.developer.apple.com/thread/17664
//    
//    
//    NSLog(@"testAirPlay");
//    
//    AudioObjectPropertyAddress propAddress;
//    propAddress.mSelector = kAudioHardwarePropertyTranslateUIDToDevice;
//    propAddress.mScope = kAudioObjectPropertyScopeGlobal;
//    propAddress.mElement = kAudioObjectPropertyElementMaster;
//    
//    CFStringRef airplayDeviceUID = CFSTR("AirPlay");
//    UInt32 dataSize = 0;
//    OSStatus ret;
//    ret = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propAddress, sizeof(CFStringRef),
//                                         &airplayDeviceUID, &dataSize);
//    
//    if (FAILED(ret)){
//        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
//        NSLog(@"Failed to get Device for AirPlay = %d(%@)", ret, [err description]);
//        return NO;
//    }
//    
//    
//    AudioDeviceID airplayDeviceId;
//    ret = AudioObjectGetPropertyData(kAudioObjectSystemObject,
//                                     &propAddress,
//                                     sizeof(CFStringRef),
//                                     &airplayDeviceUID,
//                                     &dataSize,
//                                     &airplayDeviceId);
//    
//    if (FAILED(ret)){
//        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
//        NSLog(@"Failed to get Device for AirPlay 2 = %d(%@)", ret, [err description]);
//        return NO;
//    }
//    
//    NSLog(@"deviceId for AirPlay = 0x%x", airplayDeviceId);
//    
//    
//    CFStringRef name = NULL;
//    propAddress.mSelector = kAudioObjectPropertyName;
//    UInt32 size = sizeof(CFStringRef);
//    ret = AudioObjectGetPropertyData(airplayDeviceId, &propAddress, 0, NULL, &size, &name);
//    if (FAILED(ret)){
//        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
//        NSLog(@"Failed to Get Name = %d(%@)", ret, [err description]);
//        return NO;
//    }
//    
//    
//    
//    return YES;
//    
//    
//}


@end

