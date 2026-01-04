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
    
    double _speedRate;
    
    // Fade transition for scratch ending
    Boolean _isScratchEnding;   // Transition from scratch to normal playback
    Boolean _isFadingOut;
    Boolean _isFadingIn;
    UInt32 _fadeOutCounter;
    UInt32 _fadeInCounter;
    
    // Fade transition for scratch starting
    Boolean _isScratchStarting; // Transition from normal playback to scratch
    double _pendingSpeedRate;   // Speed rate to apply after fade out
    
    // Fade transition for speed rate change (including to/from zero)
    Boolean _isSpeedChanging;   // Transition between different scratch speeds
    
    // Temporary buffers for rate conversion
    float _tempLeftPtr[1024];
    float _tempRightPtr[1024];
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;

@end

NS_ASSUME_NONNULL_END
