//
//  ReverseController.h
//  Going Zero
//
//  Created by kyab on 2021/06/13.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Reverse.h"
#import "ReverseTurntableView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReverseController : NSViewController{
    Reverse *_reverse;
    
    Boolean _btnPressing;
    
    __weak IBOutlet NSButton *_btnReverse;
    __weak IBOutlet ReverseTurntableView *_ttView;
    __weak IBOutlet NSSlider *_sliderDryVolume;
}

-(void)setReverse:(Reverse *)reverse;

@end

NS_ASSUME_NONNULL_END
