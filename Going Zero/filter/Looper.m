//
//  Looper.m
//  Going Zero
//
//  Created by kyab on 2021/06/04.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "Looper.h"

#define LOOPER_STATE_NONE        0
#define LOOPER_STATE_RECORDING   1
#define LOOPER_STATE_PLAYING     2

@implementation Looper
-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    _duration = 0;
    _state = LOOPER_STATE_NONE;
    return self;
    
}


-(void)markStart{
    [_ring reset];
    _state = LOOPER_STATE_RECORDING;
}

-(void)markEnd{
    _state = LOOPER_STATE_PLAYING;
    _duration = [_ring recordFrame];
    
}

-(void)exit{
    _state = LOOPER_STATE_NONE;
    [_ring reset];
}

-(void)doHalf{
    _duration /= 2;
    [_ring advanceReadPtrSample:-[_ring playFrame]];
    
}

-(void)doQuater{
    _duration /= 4;
    [_ring advanceReadPtrSample:-[_ring playFrame]];
}

-(void)divide8{
    _duration /= 8;
    [_ring advanceReadPtrSample:-[_ring playFrame]];
}


-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    switch(_state){
        case LOOPER_STATE_NONE:
            break;
        case LOOPER_STATE_RECORDING:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            memcpy(dstL, leftBuf, numSamples * sizeof(float));
            memcpy(dstR, rightBuf, numSamples * sizeof(float));
            [_ring advanceWritePtrSample:numSamples];
            break;
        }
        case LOOPER_STATE_PLAYING:
        {
            for(int i = 0; i < numSamples; i++){
                float *srcL = [_ring readPtrLeft];
                float *srcR = [_ring readPtrRight];
                
                leftBuf[i] = *srcL;
                rightBuf[i] = *srcR;
                
                [_ring advanceReadPtrSample:1];
                if ([_ring playFrame] >= _duration){
                    [_ring advanceReadPtrSample:-_duration];
                }
            }
        }
        default:
            break;
    }
    
}
@end
