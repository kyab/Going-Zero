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

// Scratch algorithm identifier used both by the UI checkbox and by the
// audio-thread dispatcher. The UI thread writes _selectedAlgorithm; the
// active choice is latched into _activeAlgorithm at the beginning of a
// scratch and held until the scratch has fully ended (so that switching
// the checkbox mid-scratch has no audible effect).
typedef NS_ENUM(NSInteger, TurnTableAlgorithm) {
    TurnTableAlgorithmA = 0, // original: linear interp, hard gate at speed==0
    TurnTableAlgorithmB = 1, // new:      cubic interp, sub-sample, pitch gain
};

@interface TurnTableController : NSViewController <TurnTableDelegate>{
    
    RingBuffer *_ring;
    __weak IBOutlet TurnTableView *_turnTableView;
    
    float _dryVolume;
    float _wetVolume;
    
    __weak IBOutlet NSSlider *_sliderWetVolume;
    __weak IBOutlet NSSlider *_sliderDryVolume;
    
    // ---- A/B selector -------------------------------------------------
    
    // Selected by the UI (main thread). Captured into _activeAlgorithm at
    // the moment a scratch starts and then left alone until that scratch
    // ends; this means toggling the checkbox mid-scratch is ignored on
    // purpose.
    __weak IBOutlet NSButton *_chkUseNewAlgorithm;
    TurnTableAlgorithm _selectedAlgorithm;
    TurnTableAlgorithm _activeAlgorithm;
    
    // ---- Shared scratch state ----------------------------------------
    
    double _speedRate;
    
    Boolean _isScratchStarting; // Transition: normal playback -> scratch
    Boolean _isScratchEnding;   // Transition: scratch -> normal playback
    Boolean _isFadingOut;
    Boolean _isFadingIn;
    UInt32 _fadeOutCounter;
    UInt32 _fadeInCounter;
    
    // Temporary buffers for the resampled wet signal.
    float _tempLeftPtr[1024];
    float _tempRightPtr[1024];
    
    // ---- Algorithm A state (original) ---------------------------------
    
    // A applies speed changes only at block boundaries and needs an
    // extra fade-transition state to hide the pop when |speedRate|
    // crosses zero.
    Boolean _isSpeedChangingA;
    double  _pendingSpeedRateA;
    
    // ---- Algorithm B state (xwax-inspired, smoothed) -----------------
    
    // Audio-thread-owned one-pole smoothed playback speed; avoids
    // zipper / pitch steps at block boundaries.
    double _smoothedSpeedB;
    
    // Fractional sub-sample position in [0,1) carried across blocks so
    // that a steady pitch has zero block-boundary jitter.
    double _subSamplePosB;
    
    // Pitch-proportional smoothed wet gain; natural vinyl-like
    // slowdown-to-silence, no hard gate at speed==0.
    double _wetGainB;
    
    // DC blocker for the scratched wet output.
    float _dcInLB;
    float _dcOutLB;
    float _dcInRB;
    float _dcOutRB;
    
    // Marks whether the scratch audio path is currently active (B only
    // needs this; A uses _speedRate != 1.0 as an implicit flag).
    Boolean _isScratchingB;

    // Turntable stop/start controls (Anytime-Scratch style).
    NSTimer *_tableStopTimer;
    BOOL _isTableStopping;
    BOOL _isTableStopped;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;

- (IBAction)useNewAlgorithmChanged:(id)sender;
- (IBAction)tableStopClicked:(id)sender;
- (IBAction)tableStartClicked:(id)sender;

@end

NS_ASSUME_NONNULL_END
