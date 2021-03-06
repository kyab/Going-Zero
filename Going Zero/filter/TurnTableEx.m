//
//  TurnTableEx.m
//  Going Zero
//
//  Created by kyab on 2021/06/18.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "TurnTableEx.h"

@implementation TurnTableEx

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    _speedRate = 1.0;
    _nextSpeedRate = 1.0;
    return self;
}

-(void)reset{
    _speedRate = 1.0;
    _nextSpeedRate = 1.0;
    [_ring follow];
}

-(void)setSpeedRate:(float)speedRate{
    NSLog(@"now speed rate = %f", speedRate);
//    _speedRate = _nextSpeedRate;
    _nextSpeedRate = speedRate;
//    _speedRate = speedRate;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{

    float *dstL = [_ring writePtrLeft];
    float *dstR = [_ring writePtrRight];
    memcpy(dstL, leftBuf, numSamples * sizeof(float));
    memcpy(dstR, rightBuf, numSamples * sizeof(float));
    [_ring advanceWritePtrSample:numSamples];

    
    float speedRate = _speedRate + (_nextSpeedRate - _speedRate)/(4410.0/numSamples/5);
    _speedRate = speedRate;
    
    
    if(_speedRate == 1.0){
        float *srcL = [_ring readPtrLeft];
        float *srcR = [_ring readPtrRight];
        memcpy(leftBuf, srcL, numSamples * sizeof(float));
        memcpy(rightBuf, srcR, numSamples * sizeof(float));
        [_ring advanceReadPtrSample:numSamples];
    }else{
        SInt32 consumed = 0;
        float tempL[1024];
        float tempR[1024];
        
        [self convertAtRateFromLeft:[_ring readPtrLeft] right:[_ring readPtrRight] leftDest:tempL rightDest:tempR ToSamples:numSamples rate:speedRate consumedFrames:&consumed];

        memcpy(leftBuf, tempL, numSamples * sizeof(float));
        memcpy(rightBuf,tempR, numSamples * sizeof(float));

        [_ring advanceReadPtrSample:consumed];

    }
    
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
