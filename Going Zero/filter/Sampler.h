//
//  Sampler.h
//  Going Zero
//
//  Created by kyab on 2021/06/04.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"
#import "MiniFader.h"

NS_ASSUME_NONNULL_BEGIN

#define SAMPLER_STATE_EMPTY 1
#define SAMPLER_STATE_RECORDING 2
#define SAMPLER_STATE_READYPLAY 3
#define SAMPLER_STATE_PLAYING 4


@class SamplerUnit;

@protocol SamplerUnitDelegate <NSObject>
@optional
-(void)samplerUnitStateChanged:(SamplerUnit *)samplerUnit;
@end


@interface SamplerUnit : NSObject{
    RingBuffer *_ring;
    UInt32 _state;
    UInt32 _sampleLen;
    MiniFaderIn *_faderIn;
    id<SamplerUnitDelegate> _delegate;
}

-(void)startRecord;
-(void)stopRecord;
-(void)play;
-(void)stop;
-(void)clear;
-(UInt32)state;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
-(void)setDelagate:(id<SamplerUnitDelegate>)delegate;

@end

@protocol SamplerDelegate <NSObject>
@optional
- (void) samplerStateChanged:(UInt32)index;
@end

@interface Sampler : NSObject<SamplerUnitDelegate>{
    SamplerUnit *_samplerUnits[4];
    float *_tempBuffersL[4];
    float *_tempBuffersR[4];
    id<SamplerDelegate> _delegate;
    
    float _dryVolume;
}

-(void)startRecord:(UInt32) index;
-(void)stopRecord:(UInt32) index;
-(void)play:(UInt32) index;
-(void)stop:(UInt32) index;
-(void)clear:(UInt32) index;
-(UInt32)state:(UInt32) index;
-(void)exit;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
-(void)setDelegate:(id<SamplerDelegate>)delegate;
-(void)samplerUnitStateChanged:(id)samplerUnit;
-(void)setDryVolume:(float)dryVolume;
@end


NS_ASSUME_NONNULL_END
