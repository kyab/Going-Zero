//
//  Sampler.m
//  Going Zero
//
//  Created by kyab on 2021/06/04.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "Sampler.h"
@implementation SamplerUnit

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    _state = SAMPLER_STATE_EMPTY;
    _sampleLen = 0;
    _faderIn = [[MiniFaderIn alloc] init];
    
    return self;
}

-(void)startRecord{
    _sampleLen = 0;
    [_ring reset];
    _state = SAMPLER_STATE_RECORDING;
    [_delegate samplerUnitStateChanged:self];
}

-(void)stopRecord{
    _sampleLen = (UInt32)([_ring writePtrLeft] - [_ring startPtrLeft]);
    _state = SAMPLER_STATE_READYPLAY;
    [_delegate samplerUnitStateChanged:self];

}

-(void)play{
    [_ring advanceReadPtrSample:-[_ring playFrame]];
    [_faderIn startFadeIn];
    _state = SAMPLER_STATE_PLAYING;
    [_delegate samplerUnitStateChanged:self];

}

-(void)stop{
    if (_state == SAMPLER_STATE_PLAYING){
        _state = SAMPLER_STATE_READYPLAY;
        [_delegate samplerUnitStateChanged:self];
    }
}

-(void)clear{
    _state = SAMPLER_STATE_EMPTY;
    [_delegate samplerUnitStateChanged:self];
    [_ring reset];
    _sampleLen = 0;
}

-(UInt32)state{
    return _state;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    switch(_state){
        case SAMPLER_STATE_EMPTY:
        {
            //output = 0
            memset(leftBuf, 0, numSamples * sizeof(float));
            memset(rightBuf, 0, numSamples * sizeof(float));
            break;
        }
        case SAMPLER_STATE_RECORDING:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            memcpy(dstL, leftBuf, numSamples * sizeof(float));
            memcpy(dstR, rightBuf, numSamples * sizeof(float));
            [_ring advanceWritePtrSample:numSamples];
            
            memset(leftBuf, 0, numSamples * sizeof(float));
            memset(rightBuf, 0, numSamples * sizeof(float));
            break;
        }
        case SAMPLER_STATE_READYPLAY:
        {
            //output = 0
            memset(leftBuf, 0, numSamples * sizeof(float));
            memset(rightBuf, 0, numSamples * sizeof(float));
            break;
        }
        case SAMPLER_STATE_PLAYING:
        {
            if ([_ring playFrame] > _sampleLen){
                [self performSelectorOnMainThread:@selector(stop) withObject:(nil) waitUntilDone:NO];
//                [self stop];
                break;
            }
            float *srcL = [_ring readPtrLeft];
            float *srcR = [_ring readPtrRight];
            memcpy(leftBuf, srcL, numSamples * sizeof(float));
            memcpy(rightBuf, srcR, numSamples * sizeof(float));
            [_ring advanceReadPtrSample:numSamples];
            
            [_faderIn processLeft:leftBuf right:rightBuf samples:numSamples];
            break;
        }
        default:
            break;
    }
}

-(void)setDelagate:(id<SamplerUnitDelegate>)delegate{
    _delegate = delegate;
}

@end

@implementation Sampler

-(id)init{
    self = [super init];
    for (int i = 0; i < 4; i++){
        _samplerUnits[i] = [[SamplerUnit alloc] init];
        [_samplerUnits[i] setDelagate:self];
        _tempBuffersL[i] = malloc(128/*maybe enough*/ * sizeof(float));
        _tempBuffersR[i] = malloc(128/*maybe enough*/ * sizeof(float));
    }
    
    _dryVolume = 0.0f;
    return self;
}

-(void)startRecord:(UInt32) index{
    [_samplerUnits[index] startRecord];
}

-(void)stopRecord:(UInt32) index{
    [_samplerUnits[index] stopRecord];
}

-(void)play:(UInt32) index{
    //stop all including self
    for (int i = 0 ; i < 4; i++){
        if ([_samplerUnits[i] state] == SAMPLER_STATE_PLAYING){
            [_samplerUnits[i] stop];
        }
    }
    [_samplerUnits[index] play];
}

-(void)stop:(UInt32) index{
    [_samplerUnits[index] stop];
}

-(void)clear:(UInt32) index{
    [_samplerUnits[index] clear];
}

-(UInt32)state:(UInt32) index{
    return [_samplerUnits[index] state];
}

-(void)exit{
    //stop all
    for (int i = 0 ; i < 4; i++){
        if ([_samplerUnits[i] state] == SAMPLER_STATE_PLAYING){
            [_samplerUnits[i] stop];
        }
    }
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    Boolean isPlaying = NO;
    
    for(int i = 0; i < 4; i++){
        // do parallel processing for each sampler unit.
        
        float *tempBufL = _tempBuffersL[i];
        float *tempBufR = _tempBuffersR[i];
        memcpy(tempBufL, leftBuf, numSamples * sizeof(float));
        memcpy(tempBufR, rightBuf, numSamples * sizeof(float));
        [_samplerUnits[i] processLeft:tempBufL right:tempBufR samples:numSamples];
        if ([_samplerUnits[i] state] == SAMPLER_STATE_PLAYING){
            isPlaying = YES;
        }
    }
    
    if (isPlaying){
        for (int i = 0; i < numSamples; i++){
            leftBuf[i] *= _dryVolume;
            rightBuf[i] *= _dryVolume;
        }
    }
    
    for(int i = 0; i < 4; i++){
        for (int j = 0; j < numSamples; j++){
            float *tempBufL = _tempBuffersL[i];
            float *tempBufR = _tempBuffersR[i];
            leftBuf[j] += tempBufL[j];
            rightBuf[j] += tempBufR[j];
        }
    }
}

-(void)setDelegate:(id<SamplerDelegate>)delegate{
    _delegate = delegate;
}


//forward delegate
-(void)samplerUnitStateChanged:(id)samplerUnit{
    for(UInt32 i = 0 ; i < 4; i++){
        if (samplerUnit == _samplerUnits[i]){
            [_delegate samplerStateChanged:i];
            break;
        }
    }
}

-(void)setDryVolume:(float)dryVolume{
    _dryVolume = dryVolume;
}




@end
