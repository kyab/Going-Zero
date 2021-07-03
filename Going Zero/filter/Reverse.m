//
//  Reverse.m
//  Going Zero
//
//  Created by kyab on 2021/06/13.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "Reverse.h"

@implementation Reverse

-(id)init{
    self = [super init];
    
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    
    _state = REVERSE_STATE_NORMAL;
    
    _faderIn = [[MiniFaderIn alloc] init];
    
    _dryVolume = 0.0f;
    
    return self;
}

-(void)startReverse{
    [_ring follow];
    _state = REVERSE_STATE_REVERSE;
    [_faderIn startFadeIn];
}

-(void)stopReverse{
    _state = REVERSE_STATE_NORMAL;
    [_faderIn startFadeIn];
}

-(void)setDryVolume:(float)dryVolume{
    _dryVolume = dryVolume;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    switch (_state){
        case REVERSE_STATE_NORMAL:
        {
            //store
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            
            memcpy(dstL, leftBuf, numSamples * sizeof(float));
            memcpy(dstR, rightBuf, numSamples * sizeof(float));
            
            [_ring advanceWritePtrSample:numSamples];
            
            [_faderIn processLeft:leftBuf right:rightBuf samples:numSamples];
            
        }
        break;
        
        case REVERSE_STATE_REVERSE:
        {
            for(int i = 0; i < numSamples; i++){
                leftBuf[i] *= _dryVolume;
                rightBuf[i] *= _dryVolume;
            }
            
            float *srcL = [_ring readPtrLeft];
            float *srcR = [_ring readPtrRight];
            
            for(int i = 0; i < numSamples; i++){
                leftBuf[i] += srcL[-i];
                rightBuf[i] += srcR[-i];
            }
            [_ring advanceReadPtrSample:-numSamples];
            
            [_faderIn processLeft:leftBuf right:rightBuf samples:numSamples];
            
        }
        break;
    
        default:
            break;
    }
    
    
    
}
@end
