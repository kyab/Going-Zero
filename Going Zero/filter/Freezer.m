//
//  Freezer.m
//  Going Zero
//
//  Created by kyab on 2021/05/31.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "Freezer.h"

@implementation Freezer

#define DEFAULT_GRAIN_SAMPLE_NUM 3000

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    
    _bypass = YES;
    _startL = NULL;
    _startR = NULL;
    _currentL = NULL;
    _currentR = NULL;
    
    _miniFadeIn = [[MiniFaderIn alloc] init];
    _miniFadeOut = [[MiniFaderOut alloc] init];
    
    // Fade transition for bypass switching
    _targetBypass = YES;
    _isFadingOut = NO;
    _isFadingIn = NO;
    _fadeOut = [[MiniFaderOut alloc] init];
    _fadeIn = [[MiniFaderIn alloc] init];
    _fadeOutCounter = 0;
    _fadeInCounter = 0;
    _targetGrainSize = DEFAULT_GRAIN_SAMPLE_NUM;
    _pendingGrainSizeChange = NO;
    
    _grainSize = DEFAULT_GRAIN_SAMPLE_NUM;
    
    return self;
}

-(BOOL)active{
    // During fade transition, return target state; otherwise return current state
    if (_isFadingOut || _isFadingIn) {
        return !_targetBypass;
    }
    return !_bypass;
}

-(void)setActive:(Boolean)active{
    Boolean targetBypass = !active;
    
    // Only start fade transition if state is actually changing and not already fading
    if (targetBypass != _bypass && !_isFadingOut){
        // Set target state and fade flags BEFORE sending KVO notification
        // so that active property getter returns new state when observers query it
        _targetBypass = targetBypass;
        _isFadingOut = YES;
        
        // Send KVO notification - active property will now return new state
        [self willChangeValueForKey:@"active"];
        [self didChangeValueForKey:@"active"];
        
        // Start fade transition after KVO notification
        _fadeOutCounter = FADE_SAMPLE_NUM;
        [_fadeOut startFadeOut];
    }
}

-(void)setGrainSize:(unsigned int)grainSize{
    if (grainSize == _grainSize){
        return;
    }
    
    // Store target grain size - will be applied at next grain loop boundary
    _targetGrainSize = grainSize;
    _pendingGrainSizeChange = YES;
}

// Helper: Process single sample with grain loop
-(void)processGrainLoopSample:(float *)left right:(float *)right{
    *left = *_currentL++;
    *right = *_currentR++;
    
    // Grain loop fade processing (using existing MiniFader objects)
    if (_grainSize - (_currentL - _startL) == FADE_SAMPLE_NUM){
        [_miniFadeOut startFadeOut];
    }
    if (_grainSize - (_currentL - _startL) < FADE_SAMPLE_NUM){
        [_miniFadeOut processLeft:left right:right samples:1];
    }
    if (_currentL - _startL > _grainSize){
        // Apply pending grain size change at loop boundary
        if (_pendingGrainSizeChange){
            _grainSize = _targetGrainSize;
            _pendingGrainSizeChange = NO;
        }
        
        _currentL = _startL;
        _currentR = _startR;
        [_miniFadeIn startFadeIn];
    }
    if (_currentL - _startL < FADE_SAMPLE_NUM){
        [_miniFadeIn processLeft:left right:right samples:1];
    }
}

// Helper: Change state after fade out completes
-(void)changeStateAfterFadeOut{
    if (_bypass != _targetBypass){
        _bypass = _targetBypass;
        if (!_bypass){
            // Activating: initialize ring buffer
            [_ring reset];
            _startL = [_ring writePtrLeft];
            _startR = [_ring writePtrRight];
            _currentL = [_ring writePtrLeft];
            _currentR = [_ring writePtrRight];
        }
    }
    
    // Start fade in
    _isFadingOut = NO;
    _isFadingIn = YES;
    _fadeInCounter = 0;
    [_fadeIn startFadeIn];
}

// Helper: Process samples in active state (with optional bypass fade)
-(void)processActiveState:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    // Store input to ring buffer
    float *dstL = [_ring writePtrLeft];
    float *dstR = [_ring writePtrRight];
    memcpy(dstL, leftBuf, numSamples * sizeof(float));
    memcpy(dstR, rightBuf, numSamples * sizeof(float));
    [_ring advanceWritePtrSample:numSamples];
    
    // Process each sample with grain loop
    for (int i = 0; i < numSamples; i++){
        [self processGrainLoopSample:&leftBuf[i] right:&rightBuf[i]];
        
        // Apply bypass transition fade in if active (inline for performance)
        if (_isFadingIn){
            inlineFadeInSingleSample(&leftBuf[i], &rightBuf[i], &_fadeInCounter);
            if (_fadeInCounter >= FADE_SAMPLE_NUM){
                _isFadingIn = NO;
            }
        }
    }
}

// Helper: Process samples in bypass state (with optional bypass fade)
-(void)processBypassState:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    // Pass through with fade in if active
    if (_isFadingIn){
        for (int i = 0; i < numSamples; i++){
            inlineFadeInSingleSample(&leftBuf[i], &rightBuf[i], &_fadeInCounter);
            if (_fadeInCounter >= FADE_SAMPLE_NUM){
                _isFadingIn = NO;
            }
        }
    }
    // Otherwise, pass through unchanged (do nothing)
}

// Helper: Process fade out phase - returns remaining samples to process
-(UInt32)processFadeOutPhase:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    UInt32 processed = 0;
    
    if (!_bypass){
        // Active state: process grain loop with fade out
        float *dstL = [_ring writePtrLeft];
        float *dstR = [_ring writePtrRight];
        memcpy(dstL, leftBuf, numSamples * sizeof(float));
        memcpy(dstR, rightBuf, numSamples * sizeof(float));
        [_ring advanceWritePtrSample:numSamples];
        
        for (int i = 0; i < numSamples; i++){
            [self processGrainLoopSample:&leftBuf[i] right:&rightBuf[i]];
            
            // Apply bypass transition fade out (inline for performance)
            inlineFadeOutSingleSample(&leftBuf[i], &rightBuf[i], &_fadeOutCounter);
            processed++;
            
            if (_fadeOutCounter == 0){
                [self changeStateAfterFadeOut];
                return processed; // Return number of samples processed
            }
        }
    }else{
        // Bypass state: just apply fade out to pass-through signal
        for (int i = 0; i < numSamples; i++){
            inlineFadeOutSingleSample(&leftBuf[i], &rightBuf[i], &_fadeOutCounter);
            processed++;
            
            if (_fadeOutCounter == 0){
                [self changeStateAfterFadeOut];
                return processed; // Return number of samples processed
            }
        }
    }
    
    return processed; // Fade out not complete yet
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    // Phase 1: Fade out (if active)
    if (_isFadingOut){
        UInt32 processed = [self processFadeOutPhase:leftBuf right:rightBuf samples:numSamples];
        
        // If fade out completed mid-buffer, process remaining samples with fade in
        if (processed < numSamples){
            UInt32 remaining = numSamples - processed;
            if (!_bypass){
                [self processActiveState:&leftBuf[processed] right:&rightBuf[processed] samples:remaining];
            }else{
                [self processBypassState:&leftBuf[processed] right:&rightBuf[processed] samples:remaining];
            }
        }
        return;
    }
    
    // Phase 2: Normal processing
    if (_bypass){
        [self processBypassState:leftBuf right:rightBuf samples:numSamples];
    }else{
        [self processActiveState:leftBuf right:rightBuf samples:numSamples];
    }
}

@end
