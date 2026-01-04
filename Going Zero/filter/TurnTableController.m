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
    _isScratchStarting = NO;
    _isSpeedChanging = NO;
    _isFadingOut = NO;
    _isFadingIn = NO;
    _fadeOutCounter = 0;
    _fadeInCounter = 0;
    _pendingSpeedRate = 1.0;
}

-(void)turnTableSpeedRateChanged{
    double newSpeedRate = [_turnTableView speedRate];
    
    // Already in transition - store pending speed rate
    if (_isFadingOut){
        _pendingSpeedRate = newSpeedRate;
        return;
    }
    
    // Scratch starting: transition from normal playback (==1.0) to scratch (!=1.0)
    if (_speedRate == 1.0 && newSpeedRate != 1.0){
        _isScratchStarting = YES;
        _isFadingOut = YES;
        _fadeOutCounter = FADE_SAMPLE_NUM;
        _pendingSpeedRate = newSpeedRate;
        return;
    }
    
    // Scratch ending: transition from scratch (!=1.0) to normal playback (==1.0)
    if (_speedRate != 1.0 && newSpeedRate == 1.0){
        _isScratchEnding = YES;
        _isFadingOut = YES;
        _fadeOutCounter = FADE_SAMPLE_NUM;
        return;
    }
    
    // Speed change to/from zero during scratch (causes pop noise)
    if (_speedRate != 1.0 && newSpeedRate != 1.0){
        if ((_speedRate == 0.0 && newSpeedRate != 0.0) ||
            (_speedRate != 0.0 && newSpeedRate == 0.0)){
            _isSpeedChanging = YES;
            _isFadingOut = YES;
            _fadeOutCounter = FADE_SAMPLE_NUM;
            _pendingSpeedRate = newSpeedRate;
            return;
        }
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

// Helper: Complete scratch starting transition after fade out
-(void)completeScratchStarting{
    _speedRate = _pendingSpeedRate;
    
    _isFadingOut = NO;
    _isFadingIn = YES;
    _fadeInCounter = 0;
    _isScratchStarting = NO;
}

// Helper: Complete speed change transition after fade out (to/from zero)
-(void)completeSpeedChange{
    _speedRate = _pendingSpeedRate;
    
    _isFadingOut = NO;
    _isFadingIn = YES;
    _fadeInCounter = 0;
    _isSpeedChanging = NO;
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
    
    // In normal playback: dry=0, wet=1 (input pass-through)
    // Apply fade in to wet signal only
    for (int i = 0; i < numSamples; i++){
        float dryL = leftBuf[i] * _dryVolume;
        float dryR = rightBuf[i] * _dryVolume;
        float wetL = leftBuf[i] * _wetVolume;
        float wetR = rightBuf[i] * _wetVolume;
        
        // Apply fade in to wet signal only
        if (_isFadingIn){
            float fadeRate = _fadeInCounter / (float)FADE_SAMPLE_NUM;
            wetL *= fadeRate;
            wetR *= fadeRate;
            _fadeInCounter++;
            if (_fadeInCounter >= FADE_SAMPLE_NUM){
                _isFadingIn = NO;
            }
        }
        
        leftBuf[i] = dryL + wetL;
        rightBuf[i] = dryR + wetR;
    }
}

// Helper: Process fade out phase for scratch starting (fade out normal playback)
-(UInt32)processFadeOutPhaseForScratchStart:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    UInt32 samplesToProcess = (numSamples < _fadeOutCounter) ? numSamples : _fadeOutCounter;
    
    // Advance ring buffer (normal playback)
    [_ring advanceReadPtrSample:samplesToProcess];
    
    // In normal playback: dry=0, wet=1 (input pass-through)
    // Apply fade out to wet signal only
    for (int i = 0; i < samplesToProcess; i++){
        float dryL = leftBuf[i] * _dryVolume;
        float dryR = rightBuf[i] * _dryVolume;
        float wetL = leftBuf[i] * _wetVolume;
        float wetR = rightBuf[i] * _wetVolume;
        
        // Apply fade out to wet signal only
        float fadeRate = _fadeOutCounter / (float)FADE_SAMPLE_NUM;
        wetL *= fadeRate;
        wetR *= fadeRate;
        _fadeOutCounter--;
        
        leftBuf[i] = dryL + wetL;
        rightBuf[i] = dryR + wetR;
        
        if (_fadeOutCounter == 0){
            [self completeScratchStarting];
            return i + 1;
        }
    }
    
    return samplesToProcess;
}

// Helper: Process samples in scratch state
-(void)processScratchState:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    // Speed == 0: no wet signal, dry only
    if (_speedRate == 0.0){
        for (int i = 0; i < numSamples; i++){
            float dryL = leftBuf[i] * _dryVolume;
            float dryR = rightBuf[i] * _dryVolume;
            // No wet signal when speed=0, fade in has no effect (wet=0)
            leftBuf[i] = dryL;
            rightBuf[i] = dryR;
        }
        // Clear fade in flag since there's no wet to fade
        if (_isFadingIn){
            _fadeInCounter = FADE_SAMPLE_NUM;
            _isFadingIn = NO;
        }
        return;
    }
    
    // wet - read from own RingBuffer with rate conversion
    SInt32 consumed = 0;
    [self convertAtRateFromLeft:[_ring readPtrLeft] right:[_ring readPtrRight]
                       leftDest:_tempLeftPtr rightDest:_tempRightPtr
                      ToSamples:numSamples
                           rate:_speedRate
                 consumedFrames:&consumed];
    
    for (int i = 0; i < numSamples; i++){
        float dryL = leftBuf[i] * _dryVolume;
        float dryR = rightBuf[i] * _dryVolume;
        float wetL = _tempLeftPtr[i] * _wetVolume;
        float wetR = _tempRightPtr[i] * _wetVolume;
        
        // Apply fade in to wet signal only
        if (_isFadingIn){
            float fadeRate = _fadeInCounter / (float)FADE_SAMPLE_NUM;
            wetL *= fadeRate;
            wetR *= fadeRate;
            _fadeInCounter++;
            if (_fadeInCounter >= FADE_SAMPLE_NUM){
                _isFadingIn = NO;
            }
        }
        
        leftBuf[i] = dryL + wetL;
        rightBuf[i] = dryR + wetR;
    }
    
    [_ring advanceReadPtrSample:consumed];
}

// Helper: Process fade out phase for speed change (to/from zero during scratch)
-(UInt32)processFadeOutPhaseForSpeedChange:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    UInt32 samplesToProcess = (numSamples < _fadeOutCounter) ? numSamples : _fadeOutCounter;
    
    // Process current scratch state with fade out on wet signal only
    if (_speedRate == 0.0){
        // Speed was zero - no wet signal, just dry
        for (int i = 0; i < samplesToProcess; i++){
            leftBuf[i] = leftBuf[i] * _dryVolume;
            rightBuf[i] = rightBuf[i] * _dryVolume;
            
            // No wet to fade out, just decrement counter
            _fadeOutCounter--;
            
            if (_fadeOutCounter == 0){
                [self completeSpeedChange];
                return i + 1;
            }
        }
    } else {
        // Speed was non-zero - process scratch with fade out on wet
        SInt32 consumed = 0;
        [self convertAtRateFromLeft:[_ring readPtrLeft] right:[_ring readPtrRight]
                           leftDest:_tempLeftPtr rightDest:_tempRightPtr
                          ToSamples:samplesToProcess
                               rate:_speedRate
                     consumedFrames:&consumed];
        
        [_ring advanceReadPtrSample:consumed];
        
        for (int i = 0; i < samplesToProcess; i++){
            float dryL = leftBuf[i] * _dryVolume;
            float dryR = rightBuf[i] * _dryVolume;
            float wetL = _tempLeftPtr[i] * _wetVolume;
            float wetR = _tempRightPtr[i] * _wetVolume;
            
            // Apply fade out to wet signal only
            float fadeRate = _fadeOutCounter / (float)FADE_SAMPLE_NUM;
            wetL *= fadeRate;
            wetR *= fadeRate;
            _fadeOutCounter--;
            
            leftBuf[i] = dryL + wetL;
            rightBuf[i] = dryR + wetR;
            
            if (_fadeOutCounter == 0){
                [self completeSpeedChange];
                return i + 1;
            }
        }
    }
    
    return samplesToProcess;
}

// Helper: Process fade out phase for scratch ending (fade out scratch playback)
-(UInt32)processFadeOutPhaseForScratchEnd:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    // Calculate how many samples to process in this fade out phase
    UInt32 samplesToProcess = (numSamples < _fadeOutCounter) ? numSamples : _fadeOutCounter;
    
    // Speed was zero - no wet signal, just dry
    if (_speedRate == 0.0){
        for (int i = 0; i < samplesToProcess; i++){
            leftBuf[i] = leftBuf[i] * _dryVolume;
            rightBuf[i] = rightBuf[i] * _dryVolume;
            
            // No wet to fade out, just decrement counter
            _fadeOutCounter--;
            
            if (_fadeOutCounter == 0){
                [self completeScratchEnding];
                return i + 1;
            }
        }
        return samplesToProcess;
    }
    
    // Batch rate conversion for all samples at once
    SInt32 consumed = 0;
    [self convertAtRateFromLeft:[_ring readPtrLeft] right:[_ring readPtrRight]
                       leftDest:_tempLeftPtr rightDest:_tempRightPtr
                      ToSamples:samplesToProcess
                           rate:_speedRate
                 consumedFrames:&consumed];
    
    [_ring advanceReadPtrSample:consumed];
    
    // Process dry/wet mix with fade out on wet signal only
    for (int i = 0; i < samplesToProcess; i++){
        float dryL = leftBuf[i] * _dryVolume;
        float dryR = rightBuf[i] * _dryVolume;
        float wetL = _tempLeftPtr[i] * _wetVolume;
        float wetR = _tempRightPtr[i] * _wetVolume;
        
        // Apply fade out to wet signal only
        float fadeRate = _fadeOutCounter / (float)FADE_SAMPLE_NUM;
        wetL *= fadeRate;
        wetR *= fadeRate;
        _fadeOutCounter--;
        
        leftBuf[i] = dryL + wetL;
        rightBuf[i] = dryR + wetR;
        
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
    
    // 2. Phase 1: Fade out (scratch starting, ending, or speed change)
    if (_isFadingOut){
        UInt32 processed = 0;
        
        if (_isScratchStarting){
            // Fade out normal playback, then fade in scratch
            processed = [self processFadeOutPhaseForScratchStart:leftBuf right:rightBuf samples:numSamples];
            if (processed < numSamples){
                UInt32 remaining = numSamples - processed;
                [self processScratchState:&leftBuf[processed] right:&rightBuf[processed] samples:remaining];
            }
        } else if (_isScratchEnding){
            // Fade out scratch, then fade in normal playback
            processed = [self processFadeOutPhaseForScratchEnd:leftBuf right:rightBuf samples:numSamples];
            if (processed < numSamples){
                UInt32 remaining = numSamples - processed;
                [self processNormalState:&leftBuf[processed] right:&rightBuf[processed] samples:remaining];
            }
        } else if (_isSpeedChanging){
            // Fade out current scratch speed, then fade in new speed
            processed = [self processFadeOutPhaseForSpeedChange:leftBuf right:rightBuf samples:numSamples];
            if (processed < numSamples){
                UInt32 remaining = numSamples - processed;
                [self processScratchState:&leftBuf[processed] right:&rightBuf[processed] samples:remaining];
            }
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
