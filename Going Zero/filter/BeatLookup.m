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
    _cycleFrames = (UInt32)(44100*[_beatTracker beatDurationSec]*8);
    
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
}

@end
