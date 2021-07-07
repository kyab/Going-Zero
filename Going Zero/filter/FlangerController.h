//
//  FlangerController.h
//  Going Zero
//
//  Created by kyab on 2021/07/04.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Flanger.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlangerController : NSViewController{
    __weak IBOutlet NSButton *_chkOnOff;
    
    __weak IBOutlet NSSlider *_sliderDepth;
    __weak IBOutlet NSSlider *_sliderFreq;
    Flanger *_flanger;
}

-(void)setFlanger:(Flanger *)flanger;

@end

NS_ASSUME_NONNULL_END
