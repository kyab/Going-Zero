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
    
    _grainSize = DEFAULT_GRAIN_SAMPLE_NUM;
    
    
    return self;
}

-(void)setActive:(Boolean)active{
    if (active){
        _bypass = NO;
        [_ring reset];
        _startL = [_ring writePtrLeft];
        _startR = [_ring writePtrRight];
        _currentL = [_ring writePtrLeft];
        _currentR = [_ring writePtrRight];
    }else{
        _bypass = YES;
        [_miniFadeIn startFadeIn];
    }
}

-(void)setGrainSize:(unsigned int)grainSize{
    _grainSize = grainSize;
}


-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    if(_bypass){
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
        
        if (_grainSize - (_currentL - _startL) == FADE_SAMPLE_NUM){
            [_miniFadeOut startFadeOut];
        }
        
        if (_grainSize - (_currentL - _startL) < FADE_SAMPLE_NUM){
            [_miniFadeOut processLeft:&leftBuf[i] right:&rightBuf[i] samples:1];
        }

        if(_currentL - _startL > _grainSize){
            _currentL = _startL;
            _currentR = _startR;
            [_miniFadeIn startFadeIn];
        }
        if (_currentL - _startL < FADE_SAMPLE_NUM){
            [_miniFadeIn processLeft:&leftBuf[i] right:&rightBuf[i] samples:1];
        }
    }
            
}

@end
