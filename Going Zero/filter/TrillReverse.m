//
//  TrillReverce.m
//  Going Zero
//
//  Created by kyab on 2021/05/29.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "TrillReverse.h"

@implementation TrillReverse

- (id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    
    _bypass = YES;
    _forward = YES;
    _count = 0;
    _durationSec = 0.1;
    
    _miniFadeIn = [[MiniFaderIn alloc] init];
    _miniFadeOut = [[MiniFaderOut alloc] init];
    return self;
    
}

-(void)setActive:(Boolean)active{
    if(active){
        _bypass = NO;
    }else{
        [_miniFadeIn startFadeIn];
        _bypass = YES;
    }
}

-(void)setDurationSecond:(float)durationSecond{
    _durationSec = durationSecond;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    if (_bypass){
        [_miniFadeIn processLeft:leftBuf right:rightBuf samples:numSamples];
        return;
    }
    
    //store
    float *dstL = [_ring writePtrLeft];
    float *dstR = [_ring writePtrRight];
    
    
    //process
    for (int i = 0; i < numSamples; i++){
        
        dstL[i] = leftBuf[i];
        dstR[i] = rightBuf[i];
        [_ring advanceWritePtrSample:1];
        
        
        if (![_ring readPtrLeft] || ![_ring readPtrRight]){
            NSLog(@"Bug!");
        }
        leftBuf[i] = [_ring readPtrLeft][0];
        rightBuf[i] = [_ring readPtrRight][0];
        if (_forward){
            [_ring advanceReadPtrSample:1];
            if (_count > 44100 * _durationSec - FADE_SAMPLE_NUM){
                [_miniFadeOut processLeft:&leftBuf[i] right:&rightBuf[i] samples:1];
            }
            
            if (_count < FADE_SAMPLE_NUM){
                [_miniFadeIn processLeft:&leftBuf[i] right:&rightBuf[i] samples:1];
            }
            
        }else{
            [_ring advanceReadPtrSample:-1];
            if (_count < FADE_SAMPLE_NUM){
                [_miniFadeIn processLeft:&leftBuf[i] right:&rightBuf[i] samples:1];
            }
            if (_count >  44100 * _durationSec - FADE_SAMPLE_NUM){
                [_miniFadeOut processLeft:&leftBuf[i] right:&rightBuf[i] samples:1];
            }
        }
        
        if (_count == 44100 * _durationSec - FADE_SAMPLE_NUM){
            [_miniFadeOut startFadeOut];
        }
        
        _count++;
        if (_count >= _durationSec * 44100){
            if(_forward){
                NSLog(@"now reverse");
                _forward = NO;
                [_miniFadeIn startFadeIn];
            }else{
                NSLog(@"now forward");
                _forward = YES;
                [_ring follow];
                [_miniFadeIn startFadeIn];
            }
            _count = 0;
        }
    }
}

@end
