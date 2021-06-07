//
//  Shooter.m
//  Going Zero
//
//  Created by kyab on 2021/06/07.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "Shooter.h"

@interface Shot : NSObject{
@public
    UInt32 _current;
    float _rate;
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
    
    _rate = 1.0;
    
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

-(void)setRate:(float)rate{
    _rate = rate;
}

-(void)shoot{
    Shot *shot = [[Shot alloc] init];
    shot->_current = 0;
    shot->_rate = _rate;
    
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
        {
            for (Shot *shot in _shots) {
                
                if (shot->_current < _length ){
                    
                    SInt32 consumed;
                    float tempL[1024];
                    float tempR[1024];
                    
                    float *srcL = [_ring readPtrLeft] + _startFrame + shot->_current;
                    float *srcR = [_ring readPtrRight] + _startFrame + shot->_current;
                    
                    [self convertAtRateFromLeft:srcL right:srcR leftDest:tempL rightDest:tempR ToSamples:numSamples rate:shot->_rate consumedFrames:&consumed];
                    
                    for (int i = 0; i < numSamples; i++){
                        leftBuf[i] += tempL[i];
                        rightBuf[i] += tempR[i];
                    }
                    
                    shot->_current += consumed;
                }else{
                    //TODO remove object
                }
            }
        }
            break;
        default:
            break;
            
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
