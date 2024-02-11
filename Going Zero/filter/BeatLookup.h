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
    SInt32 _barFrameStart;
    UInt32 _state;
}

-(void)setBeatTracker:(BeatTracker *)beatTracker;
-(void)setBarStart;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;

@end

NS_ASSUME_NONNULL_END
