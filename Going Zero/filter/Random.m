//
//  Random.m
//  Going Zero
//
//  Created by kyab on 2021/12/06.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "Random.h"
#import "RateConverter.h"

@implementation RandomReverse
-(id)initWithLeft:(float *)leftPtr right:(float *)rightPtr sampleNum:(UInt32)sampleNum{
    NSLog(@"RandomReverse");
    self = [super init];
    _leftPtr = leftPtr;
    _rightPtr = rightPtr;
    _length = sampleNum;
    _currentFrame = 0;
    
    return self;
    
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    for(int i=0; i < numSamples ; i++){
        leftBuf[i] = _leftPtr[_currentFrame];
        rightBuf[i] = _rightPtr[_currentFrame];
        _currentFrame--;
    }
    
}
@end

@implementation RandomAsis
-(id)initWithLeft:(float *)leftPtr right:(float *)rightPtr sampleNum:(UInt32)sampleNum{
    NSLog(@"RandomAsis");
    self = [super init];
    _leftPtr = leftPtr;
    _rightPtr = rightPtr;
    _currentFrame = 0;
    
    return self;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    for(int i=0; i < numSamples ; i++){
        leftBuf[i] = _leftPtr[_currentFrame];
        rightBuf[i] = _rightPtr[_currentFrame];
        _currentFrame++;
    }
}
@end

@implementation RandomFreeze
-(id)initWithLeft:(float *)leftPtr right:(float *)rightPtr sampleNum:(UInt32)sampleNum{
    NSLog(@"RandomFreeze");
    self = [super init];
    _leftPtr = leftPtr;
    _rightPtr = rightPtr;
    _currentFrame = 0;
    _grainSize = sampleNum/8;
    
    return self;
    
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    for(int i=0; i < numSamples ; i++){
        leftBuf[i] = _leftPtr[_currentFrame];
        rightBuf[i] = _rightPtr[_currentFrame];
        _currentFrame++;
        if(_currentFrame >= _grainSize-1){
            _currentFrame = 0;
        }
    }
}
@end


@implementation RandomTapeStop
-(id)initWithLeft:(float *)leftPtr right:(float *)rightPtr sampleNum:(UInt32)sampleNum{
    NSLog(@"RandomTapeStop");
    self = [super init];
    _leftPtr = leftPtr;
    _rightPtr = rightPtr;
    _currentFrame = 0;
    _rate = 1.0f;
    _length = sampleNum;
    return self;
    
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    float *l = _leftPtr + _currentFrame;
    float *r = _rightPtr + _currentFrame;
    
    SInt32 consumed = 0;
    [RateConverter convertAtRateFromLeft:l right:r leftDest:leftBuf rightDest:rightBuf ToSamples:numSamples rate:_rate consumedFrames:&consumed];
    
    _currentFrame += consumed;
    _rate -= (float)numSamples/_length;
    
}
@end

@implementation RandomTapeStart
-(id)initWithLeft:(float *)leftPtr right:(float *)rightPtr sampleNum:(UInt32)sampleNum{
    NSLog(@"RandomTapeStart");
    self = [super init];
    _leftPtr = leftPtr;
    _rightPtr = rightPtr;
    _currentFrame = 0;
    _rate = 0.0f;
    _length = sampleNum;
    return self;
    
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    float *l = _leftPtr + _currentFrame;
    float *r = _rightPtr + _currentFrame;
    
    SInt32 consumed = 0;
    [RateConverter convertAtRateFromLeft:l right:r leftDest:leftBuf rightDest:rightBuf ToSamples:numSamples rate:_rate consumedFrames:&consumed];
    
    _currentFrame += consumed;
    _rate += (float)numSamples/_length;
    
}
@end



@implementation Random
-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    _bypass = YES;
//    _bpm = 120.0;
    
    _filter = nil;
    srand((unsigned int)time(NULL));
    return self;
}

-(void)start{
    float bpm = [_beatTracker BPM];
    _totalLength = (UInt32)(44100.0*(60.0/bpm * 4.0));
    _sectionLength = ceil(_totalLength/4.0);
    _currentSection = 0;
    _currentFrame = 0;
    _filter = nil;
    _bypass = NO;
    
}

-(void)setBeatTracker:(BeatTracker *)beatTracker{
    _beatTracker = beatTracker;
}

-(void)newFilterLeft:(float *)leftPtr right:(float *)rightPtr samples:(UInt32)numSamples{
    
    int r = random() % 5;
    switch(r){
        case 0:
            _filter = [[RandomAsis alloc] initWithLeft:leftPtr right:rightPtr sampleNum:numSamples];
            break;
        case 1:
            _filter = [[RandomReverse alloc] initWithLeft:leftPtr right:rightPtr sampleNum:numSamples];
            break;
        case 2:
            _filter = [[RandomFreeze alloc] initWithLeft:leftPtr right:rightPtr sampleNum:numSamples];
            break;
        case 3:
            _filter = [[RandomTapeStop alloc] initWithLeft:leftPtr right:rightPtr sampleNum:numSamples];
            break;
        case 4:
            _filter = [[RandomTapeStart alloc] initWithLeft:leftPtr right:rightPtr sampleNum:numSamples];
            break;
    }
    
    
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    if(_bypass){
        float *dstL = [_ring writePtrLeft];
        float *dstR = [_ring writePtrRight];
        memcpy(dstL, leftBuf, numSamples * sizeof(float));
        memcpy(dstR, rightBuf, numSamples * sizeof(float));
        [_ring advanceWritePtrSample:numSamples];
        return;
    }
    
    //non-bypass
    if (!_filter){
        [_ring follow];
        float *startPtrLeft = [_ring readPtrLeft];
        float *startPtrRight = [_ring readPtrRight];
        [self newFilterLeft:startPtrLeft right:startPtrRight samples:_sectionLength];
    }
    {
        float *dstL = [_ring writePtrLeft];
        float *dstR = [_ring writePtrRight];
        memcpy(dstL, leftBuf, numSamples * sizeof(float));
        memcpy(dstR, rightBuf, numSamples * sizeof(float));
        [_ring advanceWritePtrSample:numSamples];
    }
    
    UInt32 nextGoalFrame = (_currentSection+1)*_sectionLength;
    if (_currentFrame + numSamples < nextGoalFrame){
        [_filter processLeft:leftBuf right:rightBuf samples:numSamples];
        [_ring advanceReadPtrSample:numSamples];
        _currentFrame += numSamples;
        if (_currentFrame >= _totalLength){
            _bypass = YES;  //exit
        }
    }else{
        UInt32 samplesToFirstProcess = numSamples - (nextGoalFrame - _currentFrame);
        [_filter processLeft:leftBuf right:rightBuf samples:samplesToFirstProcess];
        [_ring advanceReadPtrSample:samplesToFirstProcess];
        _currentFrame += samplesToFirstProcess;
        _currentSection += 1;
        if (_currentSection >= 4){
            _bypass = YES;
            return;
        }
        //change filter
        {
            float *startPtrLeft = [_ring readPtrLeft];
            float *startPtrRight = [_ring readPtrRight];
            [self newFilterLeft:startPtrLeft right:startPtrRight samples:_sectionLength];
        }
        UInt32 samplesToSecondProcess = numSamples - samplesToFirstProcess;
        float *left = leftBuf + samplesToFirstProcess;
        float *right = rightBuf + samplesToFirstProcess;
        [_filter processLeft:left right:right samples:samplesToSecondProcess];
        [_ring advanceReadPtrSample:samplesToSecondProcess];
        _currentFrame += samplesToSecondProcess;
        
    }
}
@end
