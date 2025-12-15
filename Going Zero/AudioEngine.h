//
//  AudioEngine.h
//  MyPlaythrough
//
//  Created by kyab on 2017/05/15.
//  Copyright © 2017年 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol AudioEngineDelegate <NSObject>
@optional
- (OSStatus) outCallback:(AudioUnitRenderActionFlags *)ioActionFlags inTimeStamp:(const AudioTimeStamp *) inTimeStamp inBusNumber:(UInt32) inBusNumber inNumberFrames:(UInt32)inNumberFrames ioData:(AudioBufferList *)ioData;

- (OSStatus) inCallback:(AudioUnitRenderActionFlags *)ioActionFlags inTimeStamp:(const AudioTimeStamp *) inTimeStamp inBusNumber:(UInt32) inBusNumber inNumberFrames:(UInt32)inNumberFrames /*ioData:(AudioBufferList *)ioData*/;

@end

#define ACCUM_FRAMES 256
#define CHANNELS 2

typedef struct {
    AudioUnit remoteIO;
    AudioConverterRef converter;

    // Non-interleaved input accumulate
    float inAccumL[ACCUM_FRAMES];
    float inAccumR[ACCUM_FRAMES];
    UInt32 inAccumFrames;

    // Non-interleaved output
    float outL[ACCUM_FRAMES];
    float outR[ACCUM_FRAMES];
} SRCContext;

@interface AudioEngine : NSObject{
    AUGraph _graph;
    AudioUnit _outUnit;
    AudioUnit _converterUnit;
    
    AudioUnit _inputUnit;
    
    BOOL _bIsPlaying;
    BOOL _bIsRecording;
    
    id<AudioEngineDelegate> _delegate;
    
    AudioDeviceID _preOutputDeviceID;
    
    SRCContext _srcCtx;

    
}

-(void)setRenderDelegate:(id<AudioEngineDelegate>)delegate;
-(BOOL)initialize;
-(BOOL)startOutput;
-(BOOL)stopOutput;
-(BOOL)startInput;
-(BOOL)stopInput;
-(BOOL)isPlaying;
-(BOOL)isRecording;

//system output
-(BOOL)changeSystemOutputDeviceToBGM;
-(BOOL)restoreSystemOutputDevice;


//-(BOOL)testAirPlay;

-(NSArray *)listDevices:(BOOL)output;
-(BOOL)changeInputDeviceTo:(NSString *)devName;

//called from delegate callback
- (OSStatus) readFromInput:(AudioUnitRenderActionFlags *)ioActionFlags inTimeStamp:(const AudioTimeStamp *) inTimeStamp inBusNumber:(UInt32) inBusNumber inNumberFrames:(UInt32)inNumberFrames ioData:(AudioBufferList *)ioData;
    
- (OSStatus) renderOutput:(AudioUnitRenderActionFlags *)ioActionFlags inTimeStamp:(const AudioTimeStamp *) inTimeStamp inBusNumber:(UInt32) inBusNumber inNumberFrames:(UInt32)inNumberFrames ioData:(AudioBufferList *)ioData;

- (OSStatus) inputCallback:(AudioUnitRenderActionFlags *)ioActionFlags inTimeStamp:(const AudioTimeStamp *) inTimeStamp inBusNumber:(UInt32) inBusNumber inNumberFrames:(UInt32)inNumberFrames /*ioData:(AudioBufferList *)ioData*/;

@end
