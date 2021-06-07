//
//  Sampler.m
//  Going Zero
//
//  Created by kyab on 2021/06/04.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "Sampler.h"

@implementation Sampler
-(id)init{
    self = [super init];
    
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    
    _pan = 0;
    
    return self;
}

-(UInt32)state{
    return _state;
}

-(void)setPan:(float)pan{
    _pan = pan;
}

-(void)gotoNextState{
    switch (_state) {
        case SAMPLER_STATE_READYRECORD:
            _state = SAMPLER_STATE_RECORDING;
            _startFrame = 0;
            break;
        case SAMPLER_STATE_RECORDING:
            _state = SAMPLER_STATE_READYPLAY;
            _frames = [_ring recordFrame];
            break;
        case SAMPLER_STATE_READYPLAY:
            _state = SAMPLER_STATE_PLAYING;
            
            break;
        case SAMPLER_STATE_PLAYING:
            _state = SAMPLER_STATE_READYPLAY;
            [_ring reset];
            break;
            
        default:
            break;
    }
    
}

-(void)clear{
    [_ring reset];
    _state = SAMPLER_STATE_READYRECORD;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    switch (_state){
        case SAMPLER_STATE_READYRECORD:
            break;
        case SAMPLER_STATE_RECORDING:
            {
                float *dstL = [_ring writePtrLeft];
                float *dstR = [_ring writePtrRight];
                memcpy(dstL, leftBuf, numSamples*sizeof(float));
                memcpy(dstR, rightBuf, numSamples*sizeof(float));
            
                [_ring advanceWritePtrSample:numSamples];
            }
            break;
        case SAMPLER_STATE_READYPLAY:
            
            break;
        case SAMPLER_STATE_PLAYING:
            {

                for (int i = 0; i < numSamples; i++){
                    float *srcL = [_ring readPtrLeft];
                    float *srcR = [_ring readPtrRight];

                    float volL = 1.0;
                    float volR = 1.0;
                    
                    if (_pan >= 0){
                        volL = 1.0 - _pan;
                        volR = 1.0;
                    }else{
                        volL = 1.0;
                        volR = 1.0 + _pan;
                    }
                    
                    leftBuf[i] += *srcL * volL;
                    rightBuf[i] += *srcR * volR;
                    
                    [_ring advanceReadPtrSample:1];
                    
                    if ([_ring playFrame] == _startFrame + _frames){
                        [_ring advanceReadPtrSample: -_frames];
                    }
                }
            }
            break;
        default:
            break;
       
    }
}

@end
