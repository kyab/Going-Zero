//
//  DJViewController.h
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DJViewController : NSViewController{
    
    __weak IBOutlet NSTextField *_label;
    __weak IBOutlet NSSlider *_sliderValue;
}

@end

NS_ASSUME_NONNULL_END
