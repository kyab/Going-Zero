//
//  TurnTableController.m
//  Going Zero
//
//  Created by yoshioka on 2024/01/24.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "TurnTableController.h"

@interface TurnTableController ()

@end

@implementation TurnTableController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create own RingBuffer for audio processing (like Bender pattern)
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    
    [_turnTableView setDelegate:self];
    [_turnTableView setRingBuffer:_ring];
    [_turnTableView start];
    
    _wetVolume = 1.0;
    _dryVolume = 0.0;
    _speedRate = 1.0;
    
    // Fade transition init
    _isScratchEnding = NO;
    _isFadingOut = NO;
    _isFadingIn = NO;
    _fadeOutCounter = 0;
    _fadeInCounter = 0;
}

-(void)turnTableSpeedRateChanged{
    double newSpeedRate = [_turnTableView speedRate];
    
    // Scratch ending: transition from scratch (!=1.0) to normal playback (==1.0)
    if (_speedRate != 1.0 && newSpeedRate == 1.0 && !_isFadingOut){
        _isScratchEnding = YES;
        _isFadingOut = YES;
        _fadeOutCounter = FADE_SAMPLE_NUM;
        // Don't update _speedRate yet - will be updated after fade out completes
        return;
    }
    
    _speedRate = newSpeedRate;
}

// Helper: Complete scratch ending transition after fade out
-(void)completeScratchEnding{
    _speedRate = 1.0;
    [_ring follow];
    
    _isFadingOut = NO;
    _isFadingIn = YES;
    _fadeInCounter = 0;
    _isScratchEnding = NO;
}

- (IBAction)wetVolumeChanged:(id)sender {
    _wetVolume = [_sliderWetVolume floatValue];
}

- (IBAction)dryVolumeChanged:(id)sender {
    _dryVolume = [_sliderDryVolume floatValue];
}

#pragma mark - Audio Processing

static double linearInterporation(int x0, double y0, int x1, double y1, double x){
    if (x0 == x1){
        return y0;
    }
    double rate = (x - x0) / (x1 - x0);
    double y = (1.0 - rate)*y0 + rate*y1;
    return y;
}

-(void)convertAtRateFromLeft:(float *)srcL right:(float *)srcR
                    leftDest:(float *)dstL rightDest:(float *)dstR
                   ToSamples:(UInt32)inNumberFrames
                        rate:(double)rate
              consumedFrames:(SInt32 *)consumed{
    
    if (rate == 1.0){
        memcpy(dstL, srcL, inNumberFrames * sizeof(float));
        memcpy(dstR, srcR, inNumberFrames * sizeof(float));
        *consumed = inNumberFrames;
        return;
    }
    
    [self convertAtRatePlusFromLeft:srcL right:srcR
                           leftDest:dstL rightDest:dstR
                          ToSamples:inNumberFrames
                               rate:rate
                     consumedFrames:consumed];
}

-(void)convertAtRatePlusFromLeft:(float *)srcL right:(float *)srcR
                        leftDest:(float *)dstL rightDest:(float *)dstR
                       ToSamples:(UInt32)inNumberFrames
                            rate:(double)rate
                  consumedFrames:(SInt32 *)consumed{
    
    *consumed = 0;
    
    for (int targetSample = 0; targetSample < inNumberFrames; targetSample++){
        int x0 = floor(targetSample * rate);
        int x1 = ceil(targetSample * rate);
        
        float y0_l = srcL[x0];
        float y1_l = srcL[x1];
        float y_l = linearInterporation(x0, y0_l, x1, y1_l, targetSample * rate);
        
        float y0_r = srcR[x0];
        float y1_r = srcR[x1];
        float y_r = linearInterporation(x0, y0_r, x1, y1_r, targetSample * rate);
        
        dstL[targetSample] = y_l;
        dstR[targetSample] = y_r;
        *consumed = x1;
    }
}

// Helper: Process samples in normal playback state
-(void)processNormalState:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    [_ring advanceReadPtrSample:numSamples];
    
    // Apply fade in if active
    if (_isFadingIn){
        for (int i = 0; i < numSamples; i++){
            inlineFadeInSingleSample(&leftBuf[i], &rightBuf[i], &_fadeInCounter);
            if (_fadeInCounter >= FADE_SAMPLE_NUM){
                _isFadingIn = NO;
            }
        }
    }
}

// Helper: Process samples in scratch state
-(void)processScratchState:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    // dry - use input directly (already in leftBuf/rightBuf)
    for (int i = 0; i < numSamples; i++){
        leftBuf[i] = leftBuf[i] * _dryVolume;
        rightBuf[i] = rightBuf[i] * _dryVolume;
    }
    
    // wet - read from own RingBuffer with rate conversion
    SInt32 consumed = 0;
    [self convertAtRateFromLeft:[_ring readPtrLeft] right:[_ring readPtrRight]
                       leftDest:_tempLeftPtr rightDest:_tempRightPtr
                      ToSamples:numSamples
                           rate:_speedRate
                 consumedFrames:&consumed];
    
    for (int i = 0; i < numSamples; i++){
        leftBuf[i] += _tempLeftPtr[i] * _wetVolume;
        rightBuf[i] += _tempRightPtr[i] * _wetVolume;
    }
    
    [_ring advanceReadPtrSample:consumed];
}

// Helper: Process fade out phase during scratch ending - returns processed sample count
-(UInt32)processFadeOutPhase:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    // Calculate how many samples to process in this fade out phase
    UInt32 samplesToProcess = (numSamples < _fadeOutCounter) ? numSamples : _fadeOutCounter;
    
    // Batch rate conversion for all samples at once
    SInt32 consumed = 0;
    [self convertAtRateFromLeft:[_ring readPtrLeft] right:[_ring readPtrRight]
                       leftDest:_tempLeftPtr rightDest:_tempRightPtr
                      ToSamples:samplesToProcess
                           rate:_speedRate
                 consumedFrames:&consumed];
    
    [_ring advanceReadPtrSample:consumed];
    
    // Process dry/wet mix and fade out (check each sample for fade completion)
    for (int i = 0; i < samplesToProcess; i++){
        float dryL = leftBuf[i] * _dryVolume;
        float dryR = rightBuf[i] * _dryVolume;
        
        leftBuf[i] = dryL + _tempLeftPtr[i] * _wetVolume;
        rightBuf[i] = dryR + _tempRightPtr[i] * _wetVolume;
        
        inlineFadeOutSingleSample(&leftBuf[i], &rightBuf[i], &_fadeOutCounter);
        
        // Check if fade out completed at this sample
        if (_fadeOutCounter == 0){
            [self completeScratchEnding];
            return i + 1;
        }
    }
    
    return samplesToProcess;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    // 1. Store input to own RingBuffer (Bender pattern)
    {
        float *dstL = [_ring writePtrLeft];
        float *dstR = [_ring writePtrRight];
        
        memcpy(dstL, leftBuf, numSamples * sizeof(float));
        memcpy(dstR, rightBuf, numSamples * sizeof(float));
        
        [_ring advanceWritePtrSample:numSamples];
    }
    
    // 2. Phase 1: Fade out (scratch ending)
    if (_isFadingOut){
        UInt32 processed = [self processFadeOutPhase:leftBuf right:rightBuf samples:numSamples];
        
        // If fade out completed mid-buffer, process remaining with fade in
        if (processed < numSamples){
            UInt32 remaining = numSamples - processed;
            [self processNormalState:&leftBuf[processed] right:&rightBuf[processed] samples:remaining];
        }
        return;
    }
    
    // 3. Phase 2: Normal processing
    if (_speedRate == 1.0){
        [self processNormalState:leftBuf right:rightBuf samples:numSamples];
    } else {
        [self processScratchState:leftBuf right:rightBuf samples:numSamples];
    }
}

@end
