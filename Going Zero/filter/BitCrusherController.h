//
//  BitCrusherController.h
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BitCrusher.h"

NS_ASSUME_NONNULL_BEGIN

@interface BitCrusherController : NSViewController{
    BitCrusher *_crusher;
    __weak IBOutlet NSButton *_chkActive;
}

-(void)setBitCrusher:(BitCrusher *)crusher;

@end

NS_ASSUME_NONNULL_END
