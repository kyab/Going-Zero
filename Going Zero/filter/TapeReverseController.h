//
//  TapeReverseController.h
//  Going Zero
//
//  Created by kyab on 2021/06/07.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TapeReverse.h"

NS_ASSUME_NONNULL_BEGIN

@interface TapeReverseController : NSViewController{
    TapeReverse *_tapeReverse;
    
    __weak IBOutlet NSSlider *_sliderRate;
}

-(void)setTapeReverse:(TapeReverse *)tapeReverse;

@end

NS_ASSUME_NONNULL_END
