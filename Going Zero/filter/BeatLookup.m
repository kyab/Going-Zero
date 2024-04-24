//
//  BeatLookup.m
//  Going Zero
//
//  Created by yoshioka on 2024/01/31.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "BeatLookup.h"

@implementation BeatLookup

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    _pitchShifter = [[PitchShifter alloc] init];
    _state = BL_STATE_FREERUNNING;
    _fineGrained = false;
    return self;
}

-(void)setBeatTracker:(BeatTracker *)beatTracker{
    _beatTracker = beatTracker;
}

-(void)setBarStart{
    _barFrameNum = (UInt32)(44100*[_beatTracker beatDurationSec]*4);
    NSLog(@"_barFrameNum = %d", _barFrameNum);
    SInt32 temp = [_ring recordFrame] - 2*_barFrameNum;
    if (temp > 0){
        _barFrameStart = temp;
    }else{
        _barFrameStart = [_ring frames] + temp;
    }
    _state = BL_STATE_STORING;
    
}

-(void)startBeatJuggling:(UInt32)beatRegionDivide16{
    
    if (_barFrameNum == 0){
        return;
    }
    
    NSLog(@"startBeatJuggling %d", beatRegionDivide16);
    
    UInt32 beatRegionIndex = 0;
    UInt32 framesPerRegion = 0;
    
    if (_fineGrained){
        beatRegionIndex = beatRegionDivide16;
        framesPerRegion = _barFrameNum / 16;
    }else{
        beatRegionIndex = beatRegionDivide16 / 2;
        framesPerRegion = _barFrameNum / 8;
    }
    
    SInt32 playFrameBase = (SInt32)_barFrameStart - 1*(SInt32)_barFrameNum + beatRegionIndex*framesPerRegion;
    
    UInt32 offsetFrameInRegion = [_ring offsetToRecordFrameFrom:_barFrameStart] % framesPerRegion;
    
    SInt32 playFrameTemp = playFrameBase + offsetFrameInRegion;
    UInt32 playFrame = 0;
    if (playFrameTemp >= 0){
        playFrame = playFrameTemp;
    }else{
        playFrame = [_ring frames] + playFrameTemp;
    }
    [_ring setPlayFrame:playFrame];
    
    if (playFrameBase >= 0){
        _beatJugglingContext.startFrame = playFrameBase;
    }else{
        _beatJugglingContext.startFrame = [_ring frames] + playFrameBase;
    }

    _beatJugglingContext.currentFrameInRegion = offsetFrameInRegion;
    _beatJugglingContext.framesInRegion = framesPerRegion;
    
    _state = BL_STATE_BEATJUGGLING;
}

-(void)stopBeatJuggling{
    _state = BL_STATE_STORING;
}

-(void)startPitchShifting{
    _barFrameNum = (UInt32)(44100*[_beatTracker beatDurationSec]*4);
    SInt32 start = (SInt32)[_ring recordFrame] - 2* _barFrameNum + [_pitchShifter latencyFrames];
    UInt32 uStart = 0;
    if (start >= 0){
        uStart = start;
    }else{
        uStart = [_ring frames] + start;
    }
    [_ring setCustomPtr0Sample:uStart];
    NSLog(@"startPitchShifting recordFrame = %u, start = %u", [_ring recordFrame], uStart);
    _state = BL_STATE_PITCHSHIFTING;
}

-(void)stopPitchShifting{
    _state = BL_STATE_STORING;
}

-(void)startTimeStretching{
    _barFrameNum = (UInt32)(44100*[_beatTracker beatDurationSec]*4);
    SInt32 start = (SInt32)[_ring recordFrame] - 2* _barFrameNum + [_pitchShifter latencyFrames];
    UInt32 uStart = 0;
    if (start >= 0){
        uStart = start;
    }else{
        uStart = [_ring frames] + start;
    }
    [_ring setCustomPtr0Sample:uStart];
    NSLog(@"startPitchShifting recordFrame = %u, start = %u", [_ring recordFrame], uStart);
    _state = BL_STATE_TIMESTRETCHING;
}

-(void)stopTimeStretching{
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
    
    if (_state != BL_STATE_PITCHSHIFTING){
        //Make pitch shifter smooth
        [_pitchShifter feedLeft:leftBuf right:rightBuf samples:numSamples];
    }
    
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
                if ([_ring offsetToRecordFrameFrom:_barFrameStart] > 1*_barFrameNum){
                    _barFrameStart += _barFrameNum * 1;
                    if (_barFrameStart > [_ring frames]){
                        _barFrameStart -= [_ring frames];
                    }
                }
            }
            break;
        
        case BL_STATE_BEATJUGGLING:
            {
                float *dstL = [_ring writePtrLeft];
                float *dstR = [_ring writePtrRight];
                memcpy(dstL, leftBuf, numSamples * sizeof(float));
                memcpy(dstR, rightBuf, numSamples * sizeof(float));
                [_ring advanceWritePtrSample:numSamples];
                
                if (_beatJugglingContext.currentFrameInRegion + numSamples < _beatJugglingContext.framesInRegion){
                    float *srcL = [_ring readPtrLeft];
                    float *srcR = [_ring readPtrRight];
                    memcpy(leftBuf, srcL, numSamples * sizeof(float));
                    memcpy(rightBuf, srcR, numSamples * sizeof(float));
                    [_ring advanceReadPtrSample:numSamples];
                    _beatJugglingContext.currentFrameInRegion += numSamples;
                }else{
                    UInt32 samples = _beatJugglingContext.framesInRegion - _beatJugglingContext.currentFrameInRegion;
                    float *srcL = [_ring readPtrLeft];
                    float *srcR = [_ring readPtrRight];
                    memcpy(leftBuf, srcL, samples * sizeof(float));
                    memcpy(rightBuf, srcR, samples * sizeof(float));
                    [_ring setPlayFrame:_beatJugglingContext.startFrame];
                    _beatJugglingContext.currentFrameInRegion = 0;
        
                    UInt32 samples2 = numSamples - samples;
                    srcL = [_ring readPtrLeft];
                    srcR = [_ring readPtrRight];
                    memcpy(leftBuf + samples, srcL, samples2 * sizeof(float));
                    memcpy(rightBuf + samples, srcR, samples2 * sizeof(float));
                    [_ring advanceReadPtrSample:samples2];
                    _beatJugglingContext.currentFrameInRegion = samples2;
                }
            }
            break;
        case BL_STATE_PITCHSHIFTING:
            {
                float *dstL = [_ring writePtrLeft];
                float *dstR = [_ring writePtrRight];
                memcpy(dstL, leftBuf, numSamples * sizeof(float));
                memcpy(dstR, rightBuf, numSamples * sizeof(float));
                [_ring advanceWritePtrSample:numSamples];
                
                float *srcL = [_ring customPtr0Left];
                float *srcR = [_ring customPtr0Right];
                dstL = leftBuf;
                dstR = rightBuf;
                [_pitchShifter processNonInplaceLeftIn:srcL rightIn:srcR leftOut:dstL rightOut:dstR samples:numSamples];
                [_ring advanceCustomPtr0Sample:numSamples];
            }
            break;
        case BL_STATE_TIMESTRETCHING:
            {
                float *dstL = [_ring writePtrLeft];
                float *dstR = [_ring writePtrRight];
                memcpy(dstL, leftBuf, numSamples * sizeof(float));
                memcpy(dstR, rightBuf, numSamples * sizeof(float));
                [_ring advanceWritePtrSample:numSamples];
                
                float *srcL = [_ring customPtr0Left];
                float *srcR = [_ring customPtr0Right];
                dstL = leftBuf;
                dstR = rightBuf;
                UInt32 consumedInSamples = [_pitchShifter processNonInplaceWithStretchLeftIn:srcL rightIn:srcR leftOut:dstL rightOut:dstR outNumSamples:numSamples];
                [_ring advanceCustomPtr0Sample:consumedInSamples];
            }
            break;
            
        default:
            break;
    }
}

-(UInt32)state{
    return _state;
}

-(BeatJugglingContext)beatJugglingContext{
    return _beatJugglingContext;
}

-(void)setFineGrained:(Boolean)fineGrained{
    _fineGrained = fineGrained;
}

-(void)setPitchShift:(float)pitchShift{
    [_pitchShifter setPitchShift:pitchShift];
}

-(void)setTimeStretch:(float)timeStretch{
    [_pitchShifter setTimeStretch:timeStretch];
}

@end
