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
    _timePitch = [[TimePitch alloc] init];
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

//Terminology
// Bar (1 Bar) = Full Gauge.
// Region, RegionIndex (unit for 16 divided 1 Bar).

// _beatJugglingContext.framesPerRegion : Samples in a region
// _beatJugglingContext.startFrame
// _beatJugglingContext.currentFrameInRegion

-(void)beginBeatJuggling:(UInt32)beatRegionDivide16{
    
    if (_barFrameNum == 0){
        return;
    }
    
    NSLog(@"beginBeatJuggling %d", beatRegionDivide16);
    
    if (_fineGrained){
        _beatJugglingContext.regionIndex = beatRegionDivide16;
        _beatJugglingContext.newRegionIndex = beatRegionDivide16;
        _beatJugglingContext.framesInRegion = _barFrameNum / 16;
    }else{
        _beatJugglingContext.regionIndex  = beatRegionDivide16 / 2;
        _beatJugglingContext.newRegionIndex  = beatRegionDivide16 / 2;
        _beatJugglingContext.framesInRegion = _barFrameNum / 8;
    }
    
    SInt32 playFrameBase = (SInt32)_barFrameStart - 1*(SInt32)_barFrameNum + _beatJugglingContext.regionIndex * _beatJugglingContext.framesInRegion;
    
    UInt32 offsetFrameInRegion = [_ring offsetToRecordFrameFrom:_barFrameStart] % _beatJugglingContext.framesInRegion;
    
    SInt32 playFrameTemp = playFrameBase + offsetFrameInRegion;
    UInt32 playFrame = 0;
    if (playFrameTemp >= 0){
        playFrame = playFrameTemp;
    }else{
        playFrame = playFrameTemp + [_ring frames];
    }
    [_ring setPlayFrame:playFrame];
    
    if (playFrameBase >= 0){
        _beatJugglingContext.startFrame = playFrameBase;
    }else{
        _beatJugglingContext.startFrame = playFrameBase + [_ring frames];
    }

    _beatJugglingContext.currentFrameInRegion = offsetFrameInRegion;
    
    _state = BL_STATE_BEATJUGGLING;
}

-(void)changeBeatJuggling:(UInt32)beatRegionDivide16{
    if (_fineGrained){
        _beatJugglingContext.newRegionIndex = beatRegionDivide16;
    }else{
        _beatJugglingContext.newRegionIndex  = beatRegionDivide16 / 2;
    }
}


-(void)endBeatJuggling{
    _state = BL_STATE_STORING;
}

-(void)updataBeatJugglingStateAtRegionEnd{
    
    //region index has been changed;
    if (_beatJugglingContext.regionIndex != _beatJugglingContext.newRegionIndex) {
        _beatJugglingContext.regionIndex = _beatJugglingContext.newRegionIndex;
        
        SInt32 playFrameBase = (SInt32)_barFrameStart - 1*(SInt32)_barFrameNum + _beatJugglingContext.regionIndex * _beatJugglingContext.framesInRegion;
        
        if (playFrameBase >= 0){
            _beatJugglingContext.startFrame = playFrameBase;
        }else{
            _beatJugglingContext.startFrame = playFrameBase + [_ring frames];
        }
        
    }
    [_ring setPlayFrame:_beatJugglingContext.startFrame];
    _beatJugglingContext.currentFrameInRegion = 0;
    
}

-(void)startPitchShifting{
    [_ring setCustomPtr0Sample:[_ring recordFrame]];
    _state = BL_STATE_PITCHSHIFTING;
}

-(void)stopPitchShifting{
    _state = BL_STATE_STORING;
}

-(void)beginTimeStreching{
    [_ring setCustomPtr0Sample:[_ring recordFrame]];
    _state = BL_STATE_TIMESTRETCHING;
}

-(void)endTimeStretching{
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
    
    if (_state != BL_STATE_PITCHSHIFTING && _state != BL_STATE_TIMESTRETCHING){
        //Make pitch shifter smooth
        [_timePitch feedLeft:leftBuf right:rightBuf samples:numSamples];
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
                    
                    [self updataBeatJugglingStateAtRegionEnd];
        
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
                [_timePitch processNonInplaceLeftIn:srcL rightIn:srcR leftOut:dstL rightOut:dstR samples:numSamples];
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
                UInt32 consumedInSamples = [_timePitch processNonInplaceWithStretchLeftIn:srcL rightIn:srcR leftOut:dstL rightOut:dstR outNumSamples:numSamples];
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
    [_timePitch setPitchShift:pitchShift];
}

-(void)setTimeStretch:(float)timeStretch{
    [_timePitch setTimeStretch:timeStretch];
}

@end
