//
//  TapeReverse.m
//  Going Zero
//
//  Created by kyab on 2021/06/07.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "TapeReverse.h"

@implementation TapeReverse

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    _rate = 0.0;        //means normal forward play
    _dryVolume = 0.0;
    return self;
}

-(void)setRate:(float)rate{
    _rate = rate;
    if (_rate == 0.0){
        [_ring follow];
    }
}

-(void)setDryVolume:(float)volume{
    _dryVolume = volume;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    if (_rate == 0.0){
        float *dstL = [_ring writePtrLeft];
        float *dstR = [_ring writePtrRight];
        
        memcpy(dstL, leftBuf, numSamples * sizeof(float));
        memcpy(dstR, rightBuf, numSamples * sizeof(float));
        
        [_ring advanceWritePtrSample:numSamples];
        [_ring follow];
        return;
    }
    
    
    float *srcL = [_ring readPtrLeft];
    float *srcR = [_ring readPtrRight];
    
    float tempL[1024];
    float tempR[1024];
    SInt32 consumed = 0;
    [self convertAtRateFromLeft:srcL right:srcR
                       leftDest:tempL rightDest:tempR
                      ToSamples:numSamples rate:_rate consumedFrames:&consumed];
    
    for (int i = 0; i < numSamples; i++) {
        leftBuf[i] = leftBuf[i] * _dryVolume + tempL[i];
        rightBuf[i] = rightBuf[i] * _dryVolume + tempR[i];
    }
    
    [_ring advanceReadPtrSample:consumed];
    
    
}


static double linearInterporation(int x0, double y0, int x1, double y1, double x){
    if (x0 == x1){
        return y0;
    }
    double rate = (x - x0) / (x1 - x0);
    double y = (1.0 - rate)*y0 + rate*y1;
    return y;
}


-(void)convertAtRateFromLeft:(float *)srcL right:(float *)srcR
                    leftDest:(float *)dstL rightDest:(float *)dstR
                   ToSamples:(UInt32)inNumberFrames
                        rate:(double)rate
              consumedFrames:(SInt32 *)consumed{
    
    if(rate == 1.0){
        memcpy(dstL, srcL, inNumberFrames * sizeof(float));
        memcpy(dstR, srcR, inNumberFrames * sizeof(float));
        *consumed = inNumberFrames;
        return;
        
    }
 
    [self convertAtRatePlusFromLeft:srcL right:srcR
                                leftDest:dstL
                               rightDest:dstR
                               ToSamples:inNumberFrames
                                   rate:rate
                         consumedFrames:consumed];
}


-(void)convertAtRatePlusFromLeft:(float *)srcL right:(float *)srcR
      leftDest:(float *)dstL
    rightDest:(float *)dstR
    ToSamples:(UInt32)inNumberFrames
          rate:(double)rate
consumedFrames:(SInt32 *)consumed{

    *consumed = 0;
    
    for (int targetSample = 0; targetSample < inNumberFrames; targetSample++){
        int x0 = floor(targetSample * rate);
        int x1 = ceil(targetSample * rate);
        
        float y0_l = srcL[x0];
        float y1_l = srcL[x1];
        float y_l = linearInterporation(x0, y0_l, x1, y1_l, targetSample*rate);
        
        float y0_r = srcR[x0];
        float y1_r = srcR[x1];
        float y_r = linearInterporation(x0, y0_r, x1, y1_r, targetSample*rate);

        dstL[targetSample] = y_l;
        dstR[targetSample] = y_r;
        *consumed = x1;
    }
    
}









@end
