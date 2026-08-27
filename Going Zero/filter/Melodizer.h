//
//  Melodizer.h
//  Going Zero
//
//  Created by koji on 2026/08/24.
//  Copyright © 2026 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"

NS_ASSUME_NONNULL_BEGIN


// Melodizer
// Real-time relative pitch shift via recent ring buffer

@interface Melodizer : NSObject{
    RingBuffer *_ring;
    BOOL _isPlaying;
    float _pitchShift;
    UInt32 _playedSamples;
    BOOL _isActive;
}

// -(void)replayZero;
// -(void)replayPlusOne;
// -(void)replayMinusOne;
-(void)setTranspose:(float)pitchShift;
-(void)stopTranspose;
-(void)setActive:(BOOL)active;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;

@end

NS_ASSUME_NONNULL_END

