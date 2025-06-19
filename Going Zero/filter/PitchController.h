//
//  PitchController.h
//  Going Zero
//
//  Created by koji on 2025/06/18.
//  Copyright © 2025 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Pitch.h"

NS_ASSUME_NONNULL_BEGIN

@interface PitchController : NSViewController {
    Pitch *_pitch;
    __weak IBOutlet NSSliderCell *_sliderPitch;
}

-(void)setPitch:(Pitch *)pitch;

@end

NS_ASSUME_NONNULL_END
