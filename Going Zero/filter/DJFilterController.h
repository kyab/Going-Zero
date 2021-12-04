//
//  DJViewController.h
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DJFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface DJFilterController : NSViewController{
    __weak IBOutlet NSSlider *_sliderValue;
    DJFilter *_djFilter;
}

-(void)setDJFilter:(DJFilter *)djFilter;

@end

NS_ASSUME_NONNULL_END
