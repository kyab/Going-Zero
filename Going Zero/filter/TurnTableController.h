//
//  TurnTableController.h
//  Going Zero
//
//  Created by yoshioka on 2024/01/24.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RingBuffer.h"
#import "TurnTableView.h"
#import "MiniFader.h"

NS_ASSUME_NONNULL_BEGIN

@interface TurnTableController : NSViewController <TurnTableDelegate>{
    
    RingBuffer *_ring;
    __weak IBOutlet TurnTableView *_turnTableView;
    
    float _dryVolume;
    float _wetVolume;
    
    __weak IBOutlet NSSlider *_sliderWetVolume;
    __weak IBOutlet NSSlider *_sliderDryVolume;
    
    // Target speed set by the UI thread. Smoothed on the audio thread.
    double _speedRate;
    
    // ---- Smoothed audio-thread state (xwax-inspired) -------------------
    
    // One-pole smoothed playback speed (per-sample). Avoids zipper/pitch
    // steps at block boundaries and between 100 Hz UI timer ticks.
    double _smoothedSpeed;
    
    // Fractional sub-sample position in [0,1). The integer advance is
    // pushed into the RingBuffer, the fraction stays here.
    double _subSamplePos;
    
    // Pitch-proportional wet gain, smoothed per-sample. Replaces the
    // hard gate at speed==0 (which caused pops) with a natural
    // vinyl-like slowdown-to-silence.
    double _wetGain;
    
    // DC blocker state for the scratched wet output. Resampling across
    // a bi-directional ring buffer can leave DC, which adds rumble on
    // top of the dry when mixed.
    float _dcInL;
    float _dcOutL;
    float _dcInR;
    float _dcOutR;
    
    // ---- Scratch start / end fade (kept, simplified) ------------------
    
    // Scratch is active when we are reading from the ring at a
    // user-driven rate instead of passing the input through.
    Boolean _isScratching;
    
    // Transition from normal playback (==1.0) to scratch (!=1.0)
    Boolean _isScratchStarting;
    // Transition from scratch (!=1.0) to normal playback (==1.0)
    Boolean _isScratchEnding;
    
    Boolean _isFadingOut;
    Boolean _isFadingIn;
    UInt32 _fadeOutCounter;
    UInt32 _fadeInCounter;
    
    // Temporary buffers for the resampled wet signal.
    float _tempLeftPtr[1024];
    float _tempRightPtr[1024];
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;

@end

NS_ASSUME_NONNULL_END
