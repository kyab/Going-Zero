//
//  MiscController.h
//  Going Zero
//
//  Created by yoshioka on 2024/01/17.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Bender.h"
#import "TrillReverse.h"
#import "Freezer.h"

NS_ASSUME_NONNULL_BEGIN

@interface MiscController : NSViewController{
    __weak IBOutlet NSSlider *_sliderBenderRate;
    __weak IBOutlet NSButton *_chkBenderBounce;
    __weak IBOutlet NSButton *_chkTrillReverse;
    __weak IBOutlet NSButton *_chkFreeze;
    __weak IBOutlet NSSlider *_sliderGrainSize;
    
    
    NSTimer *_benderBounceTimer;
    
    Bender *_bender;
    TrillReverse *_trillReverse;
    Freezer *_freezer;
}

-(void)setBender:(Bender *)bender;
-(void)setTrillReverse:(TrillReverse *)trillReverse;
-(void)setFreezer:(Freezer *)freezer;

@end

NS_ASSUME_NONNULL_END
