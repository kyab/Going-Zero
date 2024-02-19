//
//  BeatLookup.h
//  Going Zero
//
//  Created by yoshioka on 2024/01/31.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"
#import "BeatTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface BeatLookup : NSObject {
    RingBuffer *_ring;
    BeatTracker *_beatTracker;
    UInt32 _barFrameNum;
    UInt32 _barFrameStart;
    UInt32 _state;
    UInt32 _beatRegionDivide8;
}

-(void)setBeatTracker:(BeatTracker *)beatTracker;
-(void)setBarStart;
-(void)startBeatJuggling:(UInt32)beatRegionDivide8;
-(void)stopBeatJuggling;
-(UInt32)barFrameStart;
-(UInt32)barFrameNum;
-(RingBuffer *)ring;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;

@end

NS_ASSUME_NONNULL_END
