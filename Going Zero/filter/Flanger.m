//
//  Flanger.m
//  Going Zero
//
//  Created by kyab on 2021/07/04.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "Flanger.h"

@implementation Flanger

-(id)init{
    self = [super init];
    
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    
    _faderIn = [[MiniFaderIn alloc] init];
    
    _n = 0;
    _bypass = YES;
    _depth = 0.002;     //sec
    _freq = 0.5;        //Hz

    
    return self;
}

-(void)setBypass:(Boolean)bypass{
    _bypass = bypass;
}

-(void)setDepth:(float)depth{
    _depth = depth;
}
-(void)setFreq:(float)freq{
    _freq = freq;
    [_faderIn startFadeIn];
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    if(_bypass){
        float *dstL = [_ring writePtrLeft];
        float *dstR = [_ring writePtrRight];
        memcpy(dstL, leftBuf, numSamples * sizeof(float));
        memcpy(dstR, rightBuf, numSamples * sizeof(float));
        
//        [_ring advanceWritePtrSample:numSamples];
        return;
    }
    
    float *dstL = [_ring writePtrLeft];
    float *dstR = [_ring writePtrRight];
    memcpy(dstL, leftBuf, numSamples * sizeof(float));
    memcpy(dstR, rightBuf, numSamples * sizeof(float));
    
    [_ring advanceWritePtrSample:numSamples];
    
    float *srcL = [_ring readPtrLeft];
    float *srcR = [_ring readPtrRight];
    
    const float d = _depth * 44100;    //sample
    const float freq = _freq;
    
    for (int i = 0 ; i < numSamples; i++){
        float tau = d + _depth *44100*sin(2 * M_PI * freq * _n / 44100.0);
        _n += 1;
        leftBuf[i] += srcL[i - (int)tau];
        rightBuf[i] += srcR[i - (int)tau];
    }
    [_ring advanceReadPtrSample:numSamples];
    
    [_faderIn processLeft:leftBuf right:rightBuf samples:numSamples];
    

}


@end
