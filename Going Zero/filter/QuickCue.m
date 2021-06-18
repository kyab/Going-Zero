//
//  QuickCue.m
//  Going Zero
//
//  Created by kyab on 2021/06/15.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "QuickCue.h"
@implementation QuickCueUnit

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    
    _state = QUICKCUE_STATE_NONE;
    _cueFrame = 0;
    return self;
}

-(UInt32)state{
    return _state;
}

-(void)mark{
    _state = QUICKCUE_STATE_MARKED;
    _cueFrame = [_ring recordFrame];
    
}

-(void)play{
    _state = QUICKCUE_STATE_PLAYING;
    [_ring advanceReadPtrSample:-[_ring playFrame]];     //back
    [_ring advanceReadPtrSample:_cueFrame];
}

-(void)clear{
    _state = QUICKCUE_STATE_NONE;
    _cueFrame = 0;
}

-(void)exit{
    if (_state == QUICKCUE_STATE_NONE){
        ;
    }else if (_state == QUICKCUE_STATE_MARKED){
        ;
    }else if (_state == QUICKCUE_STATE_PLAYING){
        _state = QUICKCUE_STATE_MARKED;
    }
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    switch(_state){
        case QUICKCUE_STATE_NONE:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            memcpy(dstL, leftBuf, numSamples * sizeof(float));
            memcpy(dstR, rightBuf, numSamples * sizeof(float));
            [_ring advanceWritePtrSample:numSamples];
        }
            break;
        case QUICKCUE_STATE_MARKED:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            memcpy(dstL, leftBuf, numSamples * sizeof(float));
            memcpy(dstR, rightBuf, numSamples * sizeof(float));
            [_ring advanceWritePtrSample:numSamples];
        }
            break;
            
        case QUICKCUE_STATE_PLAYING:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            memcpy(dstL, leftBuf, numSamples * sizeof(float));
            memcpy(dstR, rightBuf, numSamples * sizeof(float));
            [_ring advanceWritePtrSample:numSamples];
            
            
            float *srcL = [_ring readPtrLeft];
            float *srcR = [_ring readPtrRight];
            memcpy(leftBuf, srcL, numSamples * sizeof(float));
            memcpy(rightBuf, srcR, numSamples * sizeof(float));
            [_ring advanceReadPtrSample:numSamples];
            
        }
            break;
        default:
            break;
    }
}


@end


@implementation QuickCue

-(id)init{
    self = [super init];
    for (int i = 0; i < QUICKCUE_NUM; i++){
        _cueUnits[i] = [[QuickCueUnit alloc] init];
    }
    
    return self;
}
-(void)mark:(UInt32)index{
    [_cueUnits[index] mark];
}
-(void)play:(UInt32)index{
    
    //stop others
    for (int i = 0; i < QUICKCUE_NUM; i++){
        [_cueUnits[i] exit];
    }
    
    [_cueUnits[index] play];
}
-(void)clear:(UInt32)index{
    [_cueUnits[index] clear];
}

-(void)exit{
    for (int i = 0; i < QUICKCUE_NUM; i++){
        [_cueUnits[i] exit];
    }
}

-(UInt32)state:(UInt32)index{
    return [_cueUnits[index] state];
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    for (int i = 0; i < QUICKCUE_NUM; i++){
        [_cueUnits[i] processLeft:leftBuf right:rightBuf samples:numSamples];
    }
}

@end
