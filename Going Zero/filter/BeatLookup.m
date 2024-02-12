//
//  BeatLookup.m
//  Going Zero
//
//  Created by yoshioka on 2024/01/31.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "BeatLookup.h"

@implementation BeatLookup

#define BL_STATE_FREERUNNING 0
#define BL_STATE_STORING 1
#define BL_STATE_INLIVE 2

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    _state = BL_STATE_FREERUNNING;
    return self;
}

-(void)setBeatTracker:(BeatTracker *)beatTracker{
    _beatTracker = beatTracker;
}

-(void)setBarStart{
    _barFrameNum = (UInt32)(44100*[_beatTracker beatDurationSec]*4);
    NSLog(@"_barFrameNum = %d", _barFrameNum);
    SInt32 temp = [_ring recordFrame] - _barFrameNum;
    if (temp > 0){
        _barFrameStart = temp;
    }else{
        _barFrameStart = [_ring frames] + temp;
    }
    _state = BL_STATE_STORING;
    
}

-(UInt32)barFrameStart{
    return _barFrameStart;
}

-(UInt32)barFrameNum{
    return _barFrameNum;
}

-(RingBuffer *)ring{
    return _ring;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    switch (_state) {
        case BL_STATE_FREERUNNING:
            {
                float *dstL = [_ring writePtrLeft];
                float *dstR = [_ring writePtrRight];
                memcpy(dstL, leftBuf, numSamples * sizeof(float));
                memcpy(dstR, rightBuf, numSamples * sizeof(float));
                [_ring advanceWritePtrSample:numSamples];
            }
            break;
        case BL_STATE_STORING:
            {
                float *dstL = [_ring writePtrLeft];
                float *dstR = [_ring writePtrRight];
                memcpy(dstL, leftBuf, numSamples * sizeof(float));
                memcpy(dstR, rightBuf, numSamples * sizeof(float));
                [_ring advanceWritePtrSample:numSamples];
                if ([_ring offsetToRecordFrameFrom:_barFrameStart] > 2*_barFrameNum){
                    _barFrameStart += _barFrameNum;
                    if (_barFrameStart > [_ring frames]){
                        _barFrameStart -= [_ring frames];
                    }
                }
            }
            break;
            
        default:
            break;
    }
    
}

@end
