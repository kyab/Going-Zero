//
//  LooperController.h
//  Going Zero
//
//  Created by koji on 2024/01/14.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Looper.h"

NS_ASSUME_NONNULL_BEGIN

@interface LooperController : NSViewController{
    Looper *_looper;
    __weak IBOutlet NSButton *_btnLooperStart;
    __weak IBOutlet NSButton *_btnLooperEnd;
    __weak IBOutlet NSButton *_btnLoopHalf;
    __weak IBOutlet NSButton *_btnLoopQuarter;
    __weak IBOutlet NSButton *_btnLooperDivide8;
    __weak IBOutlet NSButton *_btnLooperExit;
    
}

-(void)setLooper:(Looper *)looper;

@end

NS_ASSUME_NONNULL_END
