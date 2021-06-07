//
//  Refrain.m
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "Refrain.h"

@implementation Refrain

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    _state = REFRAIN_STATE_NONE;
    
    return self;
}

-(void)startMark{
    _state = REFRAIN_STATE_MARKING;
    _startFrame = [_ring recordFrame];
}

-(void)startRefrain{
    _state = REFRAIN_STATE_REFRAINING;
    [_ring advanceReadPtrSample:_startFrame];
}

-(UInt32)state{
    return _state;
}

-(void)exit{
    _state = REFRAIN_STATE_NONE;
    [_ring reset];
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    switch(_state){
        case REFRAIN_STATE_NONE:
            break;
        case REFRAIN_STATE_MARKING:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            memcpy(dstL, leftBuf, numSamples * sizeof(float));
            memcpy(dstR, rightBuf, numSamples * sizeof(float));
            [_ring advanceWritePtrSample:numSamples];
        }
            break;
        case REFRAIN_STATE_REFRAINING:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            memcpy(dstL, leftBuf, numSamples * sizeof(float));
            memcpy(dstR, rightBuf, numSamples * sizeof(float));
            [_ring advanceWritePtrSample:numSamples];
            
            
            float *srcL = [_ring readPtrLeft];
            float *srcR = [_ring readPtrRight];
            
            for(int i = 0; i < numSamples; i++){
                leftBuf[i] += srcL[i];
                rightBuf[i] += srcR[i];
            }
            
            [_ring advanceReadPtrSample:numSamples];
        }
            break;
        default:
            break;
    }
}

@end
