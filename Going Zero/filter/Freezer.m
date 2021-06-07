//
//  Freezer.m
//  Going Zero
//
//  Created by kyab on 2021/05/31.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "Freezer.h"

@implementation Freezer

#define FREEZE_SAMPLE_NUM 3000

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    
    _bypass = YES;
    _loopEndL = NULL;
    _loopEndR = NULL;
    _currentL = NULL;
    _currentR = NULL;
    
    _miniFadeIn = [[MiniFaderIn alloc] init];
    _miniFadeOut = [[MiniFaderOut alloc] init];
    
    
    return self;
}

-(void)setActive:(Boolean)active{
    if (active){
        _bypass = NO;
        _currentL = [_ring writePtrLeft];
        _currentR = [_ring writePtrRight];
        _loopEndL = _currentL + FREEZE_SAMPLE_NUM;
        _loopEndR = _currentR + FREEZE_SAMPLE_NUM;
    }else{
        _bypass = YES;
        [_miniFadeIn startFadeIn];
    }
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    if(_bypass){
        //store it
        float *dstL = [_ring writePtrLeft];
        float *dstR = [_ring writePtrRight];

        memcpy(dstL, leftBuf, numSamples*sizeof(float));
        memcpy(dstR, rightBuf, numSamples*sizeof(float));

        [_ring advanceWritePtrSample:numSamples];
        
        [_miniFadeIn processLeft:leftBuf right:rightBuf samples:numSamples];
        return;
    }
    
    {
        //store it
        float *dstL = [_ring writePtrLeft];
        float *dstR = [_ring writePtrRight];

        memcpy(dstL, leftBuf, numSamples*sizeof(float));
        memcpy(dstR, rightBuf, numSamples*sizeof(float));

        [_ring advanceWritePtrSample:numSamples];
    }
    
    for(int i = 0;i < numSamples; i++){
        leftBuf[i] = *_currentL++;
        rightBuf[i] = *_currentR++;
        
        if (_loopEndL - _currentL == FADE_SAMPLE_NUM ){
            [_miniFadeOut startFadeOut];
        }
        
        if (_loopEndL - _currentL < FADE_SAMPLE_NUM){
            [_miniFadeOut processLeft:&leftBuf[i] right:&rightBuf[i] samples:1];
        }

        
        if(_currentL == _loopEndL){
            _currentL -= FREEZE_SAMPLE_NUM;
            _currentR -= FREEZE_SAMPLE_NUM;
            [_miniFadeIn startFadeIn];
        }
        
        if (_currentL < _loopEndL - FREEZE_SAMPLE_NUM + FADE_SAMPLE_NUM){
            [_miniFadeIn processLeft:&leftBuf[i] right:&rightBuf[i] samples:1];
        }
    }
            
}

@end
