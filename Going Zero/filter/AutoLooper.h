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
    Boolean _isAutoLoop;
    UInt32 _autoLoopPhase;
    
    SInt32 _currentFrameInLoop;
    SInt32 _loopLengthFrame;
    UInt32 _baseDivider;
    UInt32 _divider;
    float _beatDurationSecForCurrentLoopSession;
    
    UInt32 _state;
}
-(void)setBeatTracker:(BeatTracker *)beatTracker;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
-(void)startQuantizedLoop;  //internal
-(void)exitLoop;
-(void)startQuantizedAutoLoop;
-(void)startQuantizedNormalLoop;
-(void)startQuantizedBounceLoop;
-(void)startQuantizedBounceLoopHalf;
-(void)startQuantizedBounceLoopQuarter;
-(void)startQuantizedBounceLoopEighth;
-(void)startQuantizedBounceLoopSixteenth;
-(void)doubleLoopLength;
-(void)halveLoopLength;
-(UInt32)baseDivider;
-(Boolean)isLooping;

@end

NS_ASSUME_NONNULL_END
