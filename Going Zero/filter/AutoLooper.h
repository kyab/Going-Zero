//
//  AutoLooper.h
//  Going Zero
//
//  Created by yoshioka on 2024/05/01.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"
#import "BeatTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface AutoLooper : NSObject{
    RingBuffer *_ring;
    BeatTracker *_beatTracker;
}
-(void)setBeatTracker:(BeatTracker *)beatTracker;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
-(void)start1BarLoop;
-(void)exitLoop;

@end

NS_ASSUME_NONNULL_END
