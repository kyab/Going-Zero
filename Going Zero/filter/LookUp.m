//
//  LookUp.m
//  Going Zero
//
//  Created by koji on 2023/05/24.
//  Copyright © 2023 kyab. All rights reserved.
//

#import "LookUp.h"

@implementation LookUp

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    _duration = 0;
    _state = LOOKUP_STATE_NONE;
    return self;
}

-(void)startMark{
    [_ring reset];
    _state = LOOKUP_STATE_MARKING;
    NSLog(@"LOOKUP_STATE_MARKING");
}

-(void)startLooping{
    _state = LOOKUP_STATE_LOOPING;
    _duration = [_ring recordFrame];
    NSLog(@"LOOKUP_STATE_LOOPING");
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSample{
    switch(_state){
        case LOOKUP_STATE_NONE:
            break;
        case LOOKUP_STATE_MARKING:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            memcpy(dstL, leftBuf, numSample * sizeof(float));
            memcpy(dstR, rightBuf, numSample * sizeof(float));
            [_ring advanceWritePtrSample:numSample];
        }
            break;
        case LOOKUP_STATE_LOOPING:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            memcpy(dstL, leftBuf, numSample * sizeof(float));
            memcpy(dstR, rightBuf, numSample * sizeof(float));
            [_ring advanceWritePtrSample:numSample];
        }
            break;
        default:
            break;
    }
}

@end
