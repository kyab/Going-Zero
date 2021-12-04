//
//  SamplerController.h
//  Going Zero
//
//  Created by kyab on 2021/11/14.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Sampler.h"

NS_ASSUME_NONNULL_BEGIN

@interface SamplerController : NSViewController<SamplerDelegate>{
    
    __weak IBOutlet NSButton *_btnShot1;
    __weak IBOutlet NSButton *_btnShot2;
    __weak IBOutlet NSButton *_btnShot3;
    __weak IBOutlet NSButton *_btnShot4;
    __weak IBOutlet NSButton *_btnClear1;
    __weak IBOutlet NSButton *_btnClear2;
    __weak IBOutlet NSButton *_btnClear3;
    __weak IBOutlet NSButton *_btnClear4;
    
    NSButton *_btnShots[4];
    
    __weak IBOutlet NSSlider *_sliderDryVolume;
    
    Sampler *_sampler;
}

-(void)setSampler:(Sampler *)sampler;

@end

NS_ASSUME_NONNULL_END
