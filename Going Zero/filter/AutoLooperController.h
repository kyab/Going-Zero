//
//  AutoLooperController.h
//  Going Zero
//
//  Created by yoshioka on 2024/05/01.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AutoLooper.h"

NS_ASSUME_NONNULL_BEGIN

@interface AutoLooperController : NSViewController {
    AutoLooper *_autoLooper;
    __weak IBOutlet NSTextField *_lblLoop;
    __weak IBOutlet NSTextField *_lblBounceLoop;
    Boolean _isLooping;
    
}

-(void)setAutoLooper:(AutoLooper *)autoLooper;
-(void)refreshLoopLabel;
-(void)toggleQuantizedLoop;
-(void)exitLoop;
-(void)startQuantizedBounceLoop;
-(void)startQuantizedBounceLoopHalf;
-(void)startQuantizedBounceLoopQuarter;
-(void)startQuantizedBounceLoopEighth;
-(void)startQuantizedBounceLoopSixteenth;
@end

NS_ASSUME_NONNULL_END
