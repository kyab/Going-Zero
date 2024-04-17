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
#import "PitchShifter.h"

NS_ASSUME_NONNULL_BEGIN

#define BL_STATE_FREERUNNING 0
#define BL_STATE_STORING 1
#define BL_STATE_INLIVE 2
#define BL_STATE_BEATJUGGLING 3
#define BL_STATE_PITCHSHIFTING 4

typedef struct {
    UInt32 startFrame;
    UInt32 currentFrameInRegion;
    UInt32 framesInRegion;
}BeatJugglingContext;

//typedef struct {
//    UInt32 startFrame;
//    UInt32 currentFrame;
//}PitchShiftingContext;

@interface BeatLookup : NSObject {
    RingBuffer *_ring;
    BeatTracker *_beatTracker;
    UInt32 _barFrameNum;
    UInt32 _barFrameStart;
    UInt32 _state;
    BeatJugglingContext _beatJugglingContext;
    Boolean _fineGrained;   //true for Divide16. Otherwise divide8
    PitchShifter *_pitchShifter;
//    PitchShiftingContext _pitchShiftingContext;
}

-(void)setBeatTracker:(BeatTracker *)beatTracker;
-(void)setBarStart;
-(void)startBeatJuggling:(UInt32)beatRegionDivide16;
-(void)stopBeatJuggling;
-(void)setPitch:(float)pitch;
-(void)startPitchShifting;
-(void)stopPitchShifting;

-(UInt32)barFrameStart;
-(UInt32)barFrameNum;
-(RingBuffer *)ring;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
-(UInt32)state;
-(BeatJugglingContext)beatJugglingContext;
-(void)setFineGrained:(Boolean)fineGrained;

@end

NS_ASSUME_NONNULL_END
