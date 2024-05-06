//
//  AutoLooper.m
//  Going Zero
//
//  Created by yoshioka on 2024/05/01.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "AutoLooper.h"


@implementation AutoLooper

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];

    _isLooping = NO;
    return self;
}

-(void)setBeatTracker:(BeatTracker *)beatTracker{
    _beatTracker = beatTracker;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    float *dstL = [_ring writePtrLeft];
    float *dstR = [_ring writePtrRight];
    memcpy(dstL, leftBuf, numSamples * sizeof(float));
    memcpy(dstR, rightBuf, numSamples * sizeof(float));
    [_ring advanceWritePtrSample:numSamples];
}

-(void)startQuantizedLoop{
    /*TODO
     直前のビートまでの時間と次のビートまでの時間を比較して、より現在に近い方をループの開始点にする。
     ループの長さもこの時点でのbeatTrackerから取得した値を使う。
     */
    float pastBeatSec = [_beatTracker pastBeatRelativeSec];
    float nextBeatSec = [_beatTracker estimatedNextBeatRelativeSec];
    float beatDurationSec = [_beatTracker beatDurationSec];
    
    NSLog(@"startQuantizedLoop, pastBeatSec=%f, nextBeatSec=%f, beatDurationSec=%f", pastBeatSec, nextBeatSec, beatDurationSec);
    if (fabs(pastBeatSec) < fabs(nextBeatSec)){
        _currentFrameInLoop = -(pastBeatSec) * 44100;
    }else{
        _currentFrameInLoop = - (beatDurationSec - nextBeatSec) * 44100;
    }
    _loopLength = beatDurationSec * 44100;
}

-(void)exitLoop{
    NSLog(@"exitLoop");
}

-(void)toggleQuantizedLoop{
    if (!_isLooping){
        [self startQuantizedLoop];
        _isLooping = YES;
    }else{
        [self exitLoop];
        _isLooping = NO;
    }
}

@end
