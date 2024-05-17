//
//  AutoLooper.m
//  Going Zero
//
//  Created by yoshioka on 2024/05/01.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "AutoLooper.h"

#define AUTOLOOPER_STATE_NONE       0
#define AUTOLOOPER_STATE_LOOPING    1

@implementation AutoLooper

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    _state = AUTOLOOPER_STATE_NONE;

    _isLooping = NO;
    _baseDivider = 1;
    _divider = _baseDivider;
    return self;
}

-(void)setBeatTracker:(BeatTracker *)beatTracker{
    _beatTracker = beatTracker;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    switch (_state){
        case AUTOLOOPER_STATE_NONE:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            memcpy(dstL, leftBuf, numSamples * sizeof(float));
            memcpy(dstR, rightBuf, numSamples * sizeof(float));
            [_ring advanceWritePtrSample:numSamples];
        }
            break;
        case AUTOLOOPER_STATE_LOOPING:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            memcpy(dstL, leftBuf, numSamples * sizeof(float));
            memcpy(dstR, rightBuf, numSamples * sizeof(float));
            [_ring advanceWritePtrSample:numSamples];
            
            if (_currentFrameInLoop + (SInt32)numSamples <= _loopLengthFrame){
                float *srcL = [_ring readPtrLeft];
                float *srcR = [_ring readPtrRight];
                memcpy(leftBuf, srcL, numSamples * sizeof(float));
                memcpy(rightBuf, srcR, numSamples * sizeof(float));
                [_ring advanceReadPtrSample:numSamples];
                _currentFrameInLoop += numSamples;
            }else{
                SInt32 samplesToCopy = _loopLengthFrame - _currentFrameInLoop;
                float *srcL = [_ring readPtrLeft];
                float *srcR = [_ring readPtrRight];
                memcpy(leftBuf, srcL, samplesToCopy * sizeof(float));
                memcpy(rightBuf, srcR, samplesToCopy * sizeof(float));
                [_ring advanceReadPtrSample:samplesToCopy];
                [_ring advanceReadPtrSample:-_loopLengthFrame];
                _currentFrameInLoop = 0;
                _loopLengthFrame = _beatDurationSecForCurrentLoopSession * 44100 / _divider;
                samplesToCopy = numSamples - samplesToCopy;
                srcL = [_ring readPtrLeft];
                srcR = [_ring readPtrRight];
                memcpy(leftBuf + samplesToCopy, srcL, samplesToCopy * sizeof(float));
                memcpy(rightBuf + samplesToCopy, srcR, samplesToCopy * sizeof(float));
                [_ring advanceReadPtrSample:samplesToCopy];
                _currentFrameInLoop += samplesToCopy;
            }
        }
            break;
        default:
            break;
    }
}

-(void)startQuantizedLoop{
    float pastBeatSec = [_beatTracker pastBeatRelativeSec];
    float beatDurationSec = [_beatTracker beatDurationSec];
    
    UInt8 region = 0;
    float posSec = fabs(pastBeatSec);
    region= (UInt32)(posSec*44100) / (UInt32)(beatDurationSec*44100 / (_divider * 2));
    UInt32 offsetFrameInRegion = (UInt32)(posSec*44100) % (UInt32)(beatDurationSec*44100 / (_divider * 2));
    UInt32 framesInRegion = (UInt32)(beatDurationSec*44100 / (_divider * 2));
    
    if (region % 2 == 0){
        _currentFrameInLoop = offsetFrameInRegion;
    }else{
        _currentFrameInLoop = framesInRegion - offsetFrameInRegion;
    }
    
    _beatDurationSecForCurrentLoopSession = beatDurationSec;
    _loopLengthFrame = _beatDurationSecForCurrentLoopSession * 44100 / _divider;
    [_ring follow];
    _state = AUTOLOOPER_STATE_LOOPING;
}


-(void)exitLoop{
    _state = AUTOLOOPER_STATE_NONE;
}

-(void)doubleLoopLength{
    if (_baseDivider == 1){
        return;
    }
    _baseDivider /= 2;
    _divider = _baseDivider;
    
    if (_state == AUTOLOOPER_STATE_LOOPING){
        _loopLengthFrame = _beatDurationSecForCurrentLoopSession * 44100 / _divider;
    }
}

-(void)halveLoopLength{
    if (_baseDivider == 16){
        return;
    }
    _baseDivider *= 2;
    _divider = _baseDivider;
    
    if (_state == AUTOLOOPER_STATE_LOOPING){
        if (_currentFrameInLoop <= _loopLengthFrame/2){
            _loopLengthFrame = _beatDurationSecForCurrentLoopSession * 44100 / _divider;
        }else{
            //update _loopLengthFrame on next rewind.
        }
    }
}

-(UInt32)baseDivider{
    return _baseDivider;
}

-(void)toggleQuantizedLoop{
    if (!_isLooping){
        _divider = _baseDivider;
        [self startQuantizedLoop];
        _isLooping = YES;
    }else{
        [self exitLoop];
        _isLooping = NO;
    }
}

-(void)startQuantizedBouneLoop{
    _divider = 1;
    [self startQuantizedLoop];
}

-(void)startQuantizedBouneLoopHalf{
    _divider = 2;
    [self startQuantizedLoop];
}

-(void)startQuantizedBouneLoopQuarter{
    _divider = 4;
    [self startQuantizedLoop];
}

-(void)startQuantizedBouneLoopEighth{
    _divider = 8;
    [self startQuantizedLoop];
}

-(void)startQuantizedBouneLoopSixteenth{
    _divider = 16;
    [self startQuantizedLoop];
}


@end
