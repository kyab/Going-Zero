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
#define BL_STATE_BEATJUGGLING 3

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
    SInt32 temp = [_ring recordFrame] - 2*_barFrameNum;
    if (temp > 0){
        _barFrameStart = temp;
    }else{
        _barFrameStart = [_ring frames] + temp;
    }
    _state = BL_STATE_STORING;
    
}

-(void)startBeatJuggling:(UInt32)beatRegionDivide8{
    UInt32 framesPerRegion = (UInt32)(2*_barFrameNum / 8.0);
    SInt32 playFrameBase = (SInt32)_barFrameStart - 2*(SInt32)_barFrameNum + beatRegionDivide8*framesPerRegion;
    
    UInt32 recordRegionDivide8 = [_ring offsetToRecordFrameFrom:_barFrameStart] /framesPerRegion;
    
    
    UInt32 offsetFrameInRegion = [_ring offsetToRecordFrameFrom:_barFrameStart + recordRegionDivide8*framesPerRegion];
    
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
                    _barFrameStart += _barFrameNum * 2;
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
            
        default:
            break;
    }
    
}

@end
