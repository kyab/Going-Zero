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
            
            if (_currentFrameInLoop + (SInt32)numSamples <= _loopLength){
                float *srcL = [_ring readPtrLeft];
                float *srcR = [_ring readPtrRight];
                memcpy(leftBuf, srcL, numSamples * sizeof(float));
                memcpy(rightBuf, srcR, numSamples * sizeof(float));
                [_ring advanceReadPtrSample:numSamples];
                _currentFrameInLoop += numSamples;
            }else{
                SInt32 samplesToCopy = _loopLength - _currentFrameInLoop;
                float *srcL = [_ring readPtrLeft];
                float *srcR = [_ring readPtrRight];
                memcpy(leftBuf, srcL, samplesToCopy * sizeof(float));
                memcpy(rightBuf, srcR, samplesToCopy * sizeof(float));
                [_ring advanceReadPtrSample:samplesToCopy];
                [_ring advanceReadPtrSample:-_loopLength];
                _currentFrameInLoop = 0;
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
    float nextBeatSec = [_beatTracker estimatedNextBeatRelativeSec];
    float beatDurationSec = [_beatTracker beatDurationSec];
    
    NSLog(@"startQuantizedLoop, pastBeatSec=%f, nextBeatSec=%f, beatDurationSec=%f", pastBeatSec, nextBeatSec, beatDurationSec);
    if (fabs(pastBeatSec) < fabs(nextBeatSec)){
        _currentFrameInLoop = -(pastBeatSec) * 44100;
    }else{
        _currentFrameInLoop = - (beatDurationSec - nextBeatSec) * 44100;
    }
    _loopLength = beatDurationSec * 44100;
    [_ring follow];
    _state = AUTOLOOPER_STATE_LOOPING;
}

-(void)startQuantizedHalfLoop{
    float pastBeatSec = [_beatTracker pastBeatRelativeSec];
    float beatDurationSec = [_beatTracker beatDurationSec];
    
    UInt8 regionDiv4 = 0;
    float posSec = fabs(pastBeatSec);
    regionDiv4 = (UInt32)(posSec*44100) / (UInt32)(beatDurationSec*44100 / 4);
    UInt32 offsetFrameInRegionDiv4 = (UInt32)(posSec*44100) % (UInt32)(beatDurationSec*44100 / 4);
    UInt32 framesInRegionDiv4 = (UInt32)(beatDurationSec*44100 / 4);
    
    if (regionDiv4 == 0){
        _currentFrameInLoop = offsetFrameInRegionDiv4;
    }else if (regionDiv4 == 1){
        _currentFrameInLoop = framesInRegionDiv4 - offsetFrameInRegionDiv4;
    }else if (regionDiv4 == 2){
        _currentFrameInLoop = offsetFrameInRegionDiv4;
    }else{
        _currentFrameInLoop = framesInRegionDiv4 - offsetFrameInRegionDiv4;
    }
    
    _loopLength = beatDurationSec * 44100 / 2;
    [_ring follow];
    _state = AUTOLOOPER_STATE_LOOPING;
}


-(void)exitLoop{
    _state = AUTOLOOPER_STATE_NONE;
}

-(void)toggleQuantizedLoop{
    if (!_isLooping){
//        [self startQuantizedLoop];
        [self startQuantizedHalfLoop];
        _isLooping = YES;
    }else{
        [self exitLoop];
        _isLooping = NO;
    }
}

@end
