//
//  BitCrasherController.h
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BitCrasher.h"

NS_ASSUME_NONNULL_BEGIN

@interface BitCrasherController : NSViewController{
    BitCrasher *_crasher;
    __weak IBOutlet NSButton *_chkActive;
}

-(void)setBitCrasher:(BitCrasher *)crasher;

@end

NS_ASSUME_NONNULL_END
