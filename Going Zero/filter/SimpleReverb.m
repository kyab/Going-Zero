//
//  SimpleReverb.m
//  Going Zero
//
//  Created by kyab on 2021/12/14.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "SimpleReverb.h"

#define SIMPLE_REVERB_DELAY 8000

@implementation SimpleReverb

-(id)init{
    self = [super init];
    
    _ringY = [[RingBuffer alloc] init];
    [_ringY setMinOffset:0];

    _bypass = YES;
    
    return self;
}

-(void)setBypass:(Boolean)bypass{
    _bypass = bypass;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    if (_bypass){
        float *yL = [_ringY writePtrLeft];
        float *yR = [_ringY writePtrRight];
        
        for (int i = 0; i < numSamples; i++){
            yL[i] = 0 + 0.7 * yL[i - SIMPLE_REVERB_DELAY];
            yR[i] = 0 + 0.7 * yR[i - SIMPLE_REVERB_DELAY];

            leftBuf[i] = leftBuf[i] + 0.7* yL[i- SIMPLE_REVERB_DELAY];
            rightBuf[i] = rightBuf[i] + 0.7 * yR[i-SIMPLE_REVERB_DELAY];

        }
        [_ringY advanceWritePtrSample:numSamples];
        
        return;
    }
    
    float *yL = [_ringY writePtrLeft];
    float *yR = [_ringY writePtrRight];
    
    for (int i = 0; i < numSamples; i++){
        yL[i] = leftBuf[i] + 0.7 * yL[i - SIMPLE_REVERB_DELAY];
        yR[i] = rightBuf[i] + 0.7 * yR[i - SIMPLE_REVERB_DELAY];
    }
    [_ringY advanceWritePtrSample:numSamples];
    
    memcpy(leftBuf, yL, numSamples*sizeof(float));
    memcpy(rightBuf, yR, numSamples*sizeof(float));
    
    
}



@end
