//
//  Shooter.m
//  Going Zero
//
//  Created by kyab on 2021/06/07.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "Shooter.h"

#define GRAIN_SIZE 6000

@interface Shot : NSObject{
@public
    UInt32 _current;
    float _rate;            //length rate;
    float pan;
    UInt32 length;
    SInt32 current_x;
    SInt32 current_grain_start;
    SInt32 current_x2;
    SInt32 current_grain_start2;
}
@end

@implementation Shot
@end

@implementation Shooter

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    
    _state = SHOOTER_STATE_NONE;
    _startFrame = _length = 0;
    
    _shots = [[NSMutableArray alloc] init];
    
    _pitch = 1.0;
    _pan = 0.0;
    
    return self;
}

-(void)recOrExit{
    switch(_state){
        case SHOOTER_STATE_NONE:
        {
            _startFrame = [_ring recordFrame];
            _state = SHOOTER_STATE_RECORDING;
        }
            break;
        case SHOOTER_STATE_RECORDING:
        {
            SInt32 current = [_ring recordFrame];
            if (current < _startFrame){
                _length = current + ([_ring frames]-_startFrame);
            }else{
                _length = current - _startFrame;
            }
            _state = SHOOTER_STATE_READY;
        }
            break;
        case SHOOTER_STATE_READY:
            [_ring reset];
            _startFrame = 0;
            _length = 0;
            [_shots removeAllObjects];
            _state = SHOOTER_STATE_NONE;
            
            break;
        default:
            break;
    }
}


-(UInt32)state{
    return _state;
}

-(void)setPitch:(float)pitch{
    _pitch = pitch;
}

-(float)pitch{
    return _pitch;
}

-(void)setPan:(float)pan{
    _pan = pan;
}

-(void)shoot{
    Shot *shot = [[Shot alloc] init];
    shot->_current = 0;
    shot->_rate = _pitch;
    shot->pan = _pan;
    shot->length = _length;
    
    
    if (shot->_rate >= 1){
        shot->current_x = 0;
        shot->current_grain_start = 0;
        shot->current_grain_start2 = GRAIN_SIZE/2;
        shot->current_x2 = -1 * round(GRAIN_SIZE/2 * shot->_rate);
    }else{
        NSLog(@"shot");
        shot->current_x = 0;
        shot->current_grain_start = 0;
        shot->current_grain_start2 = GRAIN_SIZE;
        shot->current_x2 = -1 * round(GRAIN_SIZE * shot->_rate);
    }

    
    [_shots addObject:shot];
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    switch(_state){
        case SHOOTER_STATE_NONE:
            //do nothing
            break;
            
        case SHOOTER_STATE_RECORDING:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            
            memcpy(dstL, leftBuf, numSamples * sizeof(float));
            memcpy(dstR, rightBuf, numSamples * sizeof(float));
            
            [_ring advanceWritePtrSample:numSamples];
        }
            break;
        
        case SHOOTER_STATE_READY:
            if ([_shots count] >= 1){
                [self processShotsLeft:leftBuf right:rightBuf samples:numSamples];
            }

            break;
        default:
            break;
            
    }
}



-(void)getAtShot:(Shot *)shot offset:(SInt32)offset
         outLeft:(float *)retValL outRight:(float *)retValR{
    
    float ratio = shot->_rate;
    float fadeStartRate;// = -1/2.0 * ratio + 1;
    
    SInt32 current_x = shot->current_x;
    SInt32 current_grain_start = shot->current_grain_start;
    SInt32 current_x2 = shot->current_x2;
    SInt32 current_grain_start2 = shot->current_grain_start2;
    
    *retValL = 0;
    *retValR = 0;
    
    if (ratio >= 1){
        fadeStartRate = -1/2.0 * ratio + 1;
        for(UInt32 c = 0; c < offset; c++){
            if( current_x > GRAIN_SIZE * (1+(ratio-1)/2) ){
                current_grain_start += GRAIN_SIZE;
                current_x = round( (GRAIN_SIZE*(1+(ratio-1)/2) - GRAIN_SIZE) * (-1) );
            }
            if( current_x2 > GRAIN_SIZE * (1+(ratio-1)/2) ){
                current_grain_start2 += GRAIN_SIZE;
                current_x2 = round( (GRAIN_SIZE*(1+(ratio-1)/2) - GRAIN_SIZE) * (-1) );
            }
            
            current_x++;
            current_x2++;
        }
    }else{
        fadeStartRate = 1.0 - ratio;
        for(UInt32 c = 0; c < offset; c++){
            if( current_x > GRAIN_SIZE * (1+ ratio -  1/2.0) ){
                current_grain_start += GRAIN_SIZE *2 ;
                current_x = round( GRAIN_SIZE * (ratio -1 /2.0 ) * (-1));
            }
            if( current_x2 > GRAIN_SIZE * (1+ ratio -  1/2.0) ){
                current_grain_start2 += GRAIN_SIZE *2 ;
                current_x2 = round( GRAIN_SIZE * (ratio -1 /2.0 ) * (-1));
            }
            
            current_x++;
            current_x2++;
        }
    }
    {
        const SInt32 x = current_grain_start + current_x;
        float valL = 0;
        float valR = 0;
        
        if (0 <= x){
            float *leftPtr = [_ring startPtrLeft];
            float *rightPtr = [_ring startPtrRight];
            valL = *(leftPtr + x);
            valR = *(rightPtr + x);

            if (current_x2 < 0){

            }else{
                valL = sinFadeWindow(fadeStartRate , 1.0*current_x / GRAIN_SIZE, valL);
                valR = sinFadeWindow(fadeStartRate , 1.0*current_x / GRAIN_SIZE, valR);
            }
            
            *retValL += valL;
            *retValR += valR;
        }
    }
    {
        const SInt32 x2 = current_grain_start2 + current_x2;
        float valL2 = 0;
        float valR2 = 0;
        
        if (0 <= x2){
            float *leftPtr = [_ring startPtrLeft];
            float *rightPtr = [_ring startPtrRight];
            
            valL2 = *(leftPtr + x2);
            valR2 = *(rightPtr + x2);
            
            valL2 = sinFadeWindow(fadeStartRate , 1.0*current_x2 / GRAIN_SIZE, valL2);
            valR2 = sinFadeWindow(fadeStartRate , 1.0*current_x2 / GRAIN_SIZE, valR2);
            
            *retValL += valL2;
            *retValR += valR2;
        }
    }
}
-(void)consumeShot:(Shot *)shot offset:(SInt32) offset{
    float ratio = shot->_rate;
    if (ratio >= 1){
        for (UInt32 c = 0; c < offset; c++){

            if( shot->current_x > GRAIN_SIZE * (1+(ratio-1)/2) ){
                shot->current_grain_start += GRAIN_SIZE;
                shot->current_x = round( (GRAIN_SIZE*(1+(ratio-1)/2) - GRAIN_SIZE) * (-1) );
            }
            if( shot->current_x2 > GRAIN_SIZE * (1+(ratio-1)/2) ){
                shot->current_grain_start2 += GRAIN_SIZE;
                shot->current_x2 = round( (GRAIN_SIZE*(1+(ratio-1)/2) - GRAIN_SIZE) * (-1) );
            }
            
            shot->current_x++;
            shot->current_x2++;
        }
    }else{
        for (UInt32 c = 0; c < offset; c++){

            if( shot->current_x > GRAIN_SIZE * (1 + ratio - 1 / 2.0)) {
                shot->current_grain_start += GRAIN_SIZE * 2;
                shot->current_x = round(GRAIN_SIZE * (ratio - 1 / 2.0) * (-1));
            }
            if (shot->current_x2 > GRAIN_SIZE * (1 + ratio - 1 / 2.0)) {
                shot->current_grain_start2 += GRAIN_SIZE * 2;
                shot->current_x2 = round(GRAIN_SIZE * (ratio - 1 / 2.0) * (-1));
            }
            
            shot->current_x++;
            shot->current_x2++;
        }
    }
    
    
}

float sinFadeWindow(float fadeStartRate, float x, float val){
    float y = 0;
    if (x < 0 || x > 1) {
        return 0;
    }
    if (x < fadeStartRate){
        y = 1.0/2.0*sin(M_PI / fadeStartRate * x + 3.0 /2 * M_PI) + 1.0/2;
    }else if (x < 1.0 - fadeStartRate) {
        y = 1.0;
    }else{
        y = 1.0/2.0*sin(M_PI / fadeStartRate * x + 3.0 / 2.0 * M_PI
                          -1.0/fadeStartRate * M_PI) + 1.0 / 2.0;
    }
    return val * y;

}


-(void)processShotsLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    for (Shot *shot in _shots) {
        if (!shot) return;
        
        if (shot->_current < shot->length){
            SInt32 required = ceil(numSamples * shot->_rate);// + 1;              //length rate

            float tempL[1024];
            float tempR[1024];

            for(UInt32 i = 0; i < required; i++){
                float left = 0.0;
                float right = 0.0;
                [self getAtShot:shot offset:i outLeft:&left outRight:&right];
                tempL[i] = left;
                tempR[i] = right;

            }
            [self consumeShot:shot offset:required];

            float tempL2[1024];
            memset(tempL2, 0, 1024*sizeof(float));
            float tempR2[1024];
            memset(tempR2, 0, 1024*sizeof(float));
            SInt32 consumed = 0;

            [self convertAtRateFromLeft:tempL right:tempR leftDest:tempL2 rightDest:tempR2 ToSamples:numSamples rate:shot->_rate consumedFrames:&consumed];

            
            float volL = 1.0;
            float volR = 1.0;
            if (shot->pan >= 0.0){
                volL = 1.0 - shot->pan;
            }else{
                volR = 1.0 + shot->pan;
            }
            
            for (UInt32 i = 0 ; i < numSamples; i++){
                leftBuf[i] += tempL2[i] * volL;
                rightBuf[i] += tempR2[i] * volR;
            }
            
            shot->_current += numSamples;

        }else{
        }
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
