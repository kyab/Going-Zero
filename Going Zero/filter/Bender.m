//
//  Bender.m
//  Going Zero
//
//  Created by kyab on 2021/05/30.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "Bender.h"

@implementation Bender

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    
    _rate = 1.0;
    _bypass = NO;
    
    _miniFadeIn = [[MiniFaderIn alloc] init];
    
    _bounce = false;
    
    return self;
}

-(void)setRate:(float)rate{
    _rate = rate;
}

-(void)resetRate{
    _rate = 1.0;
    [_ring follow];
    [_miniFadeIn startFadeIn];
}

-(void)setActive:(Boolean)active{
    if(active){
        _bypass = NO;
    }else{
        _bypass = YES;
        [_miniFadeIn startFadeIn];
    }
}

-(void)setBounce:(Boolean)bounce{
    _bounce = bounce;
}

-(Boolean)bounce{
    return _bounce;
}

-(Boolean)isCatchingUp{
    if ([_ring readWriteOffset] <= 32){
        return YES;
    }else{
        return NO;
    }
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    if(_bypass){
        [_miniFadeIn processLeft:leftBuf right:rightBuf samples:numSamples];
        return;
    }
    
    //store
    {
        float *dstL = [_ring writePtrLeft];
        float *dstR = [_ring writePtrRight];
        
        memcpy(dstL, leftBuf, numSamples * sizeof(float));
        memcpy(dstR, rightBuf, numSamples * sizeof(float));
        
        [_ring advanceWritePtrSample:numSamples];
        
        [_miniFadeIn processLeft:leftBuf right:rightBuf samples:numSamples];
    }
    
    //drop stored with rate change
    {
        float *srcL = [_ring readPtrLeft];
        float *srcR = [_ring readPtrRight];
        if (!srcL || !srcR){
            NSLog(@"shortage");
            memset(leftBuf, 0, numSamples * sizeof(float));
            memset(rightBuf, 0, numSamples * sizeof(float));
            [_ring follow];
            return;
        }
        
        //how much will it consume?
        SInt32 estimatedConsume = ceil(numSamples * _rate);
        if (estimatedConsume > [_ring readWriteOffset]){
            memset(leftBuf, 0, numSamples * sizeof(float));
            memset(rightBuf, 0, numSamples * sizeof(float));
            [_ring follow];
            
            return;
        }
        
        float tempL[1024];
        float tempR[1024];
        SInt32 consumed = 0;
        [self convertAtRateFromLeft:srcL right:srcR
                           leftDest:tempL rightDest:tempR
                          ToSamples:numSamples rate:_rate consumedFrames:&consumed];
        
        memcpy(leftBuf, tempL, numSamples*sizeof(float));
        memcpy(rightBuf, tempR, numSamples*sizeof(float));
        
        [_ring advanceReadPtrSample:consumed];
        
        [_miniFadeIn processLeft:leftBuf right:rightBuf samples:numSamples];

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
