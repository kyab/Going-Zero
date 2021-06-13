//
//  VocalRefrainController.h
//  Going Zero
//
//  Created by kyab on 2021/06/12.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VocalRefrain.h"

NS_ASSUME_NONNULL_BEGIN

@interface VocalRefrainController : NSViewController{
    VocalRefrain *_vocalRefrain;
    __weak IBOutlet NSButton *_btnMark;
    __weak IBOutlet NSSlider *_sliderPan;
}

-(void)setVocalRefrain:(VocalRefrain *)vocalRefrain;

@end

NS_ASSUME_NONNULL_END
