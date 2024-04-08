//
//  PitchShifterController.h
//  Going Zero
//
//  Created by yoshioka on 2024/04/08.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PitchShifter.h"

NS_ASSUME_NONNULL_BEGIN

@interface PitchShifterController : NSViewController {
    
    __weak IBOutlet NSSlider *_sliderPitch;
    PitchShifter *_pitchShifter;
}

-(void)setPitchShifter:(PitchShifter *)pitchShifter;

@end

NS_ASSUME_NONNULL_END
