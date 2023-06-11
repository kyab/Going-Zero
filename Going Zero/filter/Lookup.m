//
//  LookUp.m
//  Going Zero
//
//  Created by koji on 2023/05/24.
//  Copyright © 2023 kyab. All rights reserved.
//

#import "Lookup.h"

@implementation Lookup

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    _duration = 0;
    _baseFrame = 0;
    _recordBaseFrame = 0;
    _state = LOOKUP_STATE_NONE;
    return self;
}

-(void)startMark{
    [_ring reset];
    _state = LOOKUP_STATE_MARKING;
    NSLog(@"LOOKUP_STATE_MARKING");
}

-(void)startLooping{
    _duration = [_ring recordFrame];
    _baseFrame = 0;
    _recordBaseFrame = _duration;
    _state = LOOKUP_STATE_LOOPING;
    NSLog(@"LOOKUP_STATE_LOOPING");
}

-(void)updateBaseIfNeeded{
    UInt32 recordFrame = [_ring recordFrame];
    if (recordFrame >= _recordBaseFrame){
        if (recordFrame >= (_recordBaseFrame + _duration)){
            _recordBaseFrame = recordFrame;
            _baseFrame = _recordBaseFrame - _duration;
        }
    }else{
        if (recordFrame + [_ring frames] - _recordBaseFrame >= _duration){
            _recordBaseFrame = recordFrame;
            SInt32 tmpBaseFrame = _recordBaseFrame - _duration;
            if (tmpBaseFrame < 0){
                _baseFrame = [_ring frames] + tmpBaseFrame;
            }else{
                _baseFrame = tmpBaseFrame;
            }
        }
    }
}

-(void)startLookupping:(double)ratio{
    _playStartRatio = ratio;
    
    UInt32 offset = (UInt32)(_playStartRatio*_duration);
    
    _playStartFrame = _baseFrame + offset;
    if (_playStartFrame > [_ring frames]){
        _playStartFrame -= [_ring frames];
    }
    [_ring setPlayFrame: _playStartFrame];
    
    _state = LOOKUP_STATE_LOOKUPPING;
    NSLog(@"LOOKUP_STATE_LOOKUPPING");
}

-(void)stopLookupping{
    _state = LOOKUP_STATE_LOOPING;
    NSLog(@"back to LOOKUP_STATE_LOOPING");
}

-(void)manageLoop{
    SInt32 playedFrames = [_ring playFrame] - _playStartFrame;
    if (playedFrames < 0) {
        playedFrames += [_ring frames];
    }
    if (playedFrames >= _duration / 8){
        UInt32 offset = (UInt32)(_playStartRatio*_duration);
        
        _playStartFrame = _baseFrame + offset;
        if (_playStartFrame > [_ring frames]){
            _playStartFrame -= [_ring frames];
        }
        [_ring setPlayFrame: _playStartFrame];
    }
}

-(UInt32)playFrameInBar{
    SInt32 playedFramesInThisLoop = [_ring playFrame] - _baseFrame;
    if (playedFramesInThisLoop < 0) {
        playedFramesInThisLoop += [_ring frames];
    }
    return (UInt32)playedFramesInThisLoop;
}

-(UInt32)recordFrameInBar{
    SInt32 recordedFramesInThisLoop = [_ring recordFrame] - _recordBaseFrame;
    if (recordedFramesInThisLoop < 0){
        recordedFramesInThisLoop += [_ring frames];
    }
    return (UInt32)recordedFramesInThisLoop;
}

-(UInt32)barDuration{
    return _duration;
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
            
            [self updateBaseIfNeeded];
        }
            break;
            
        case LOOKUP_STATE_LOOKUPPING:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            memcpy(dstL, leftBuf, numSample * sizeof(float));
            memcpy(dstR, rightBuf, numSample * sizeof(float));
            [_ring advanceWritePtrSample:numSample];
            
            float *srcL = [_ring readPtrLeft];
            float *srcR = [_ring readPtrRight];
            memcpy(leftBuf, srcL, numSample * sizeof(float));
            memcpy(rightBuf, srcR, numSample * sizeof(float));
            [_ring advanceReadPtrSample:numSample];
            
            [self updateBaseIfNeeded];
            [self manageLoop];
        }
            break;
        default:
            break;
    }
}

//https://www.switch-science.com/products/283

@end
