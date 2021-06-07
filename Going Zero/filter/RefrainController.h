//
//  RefrainController.h
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Refrain.h"

NS_ASSUME_NONNULL_BEGIN

@interface RefrainController : NSViewController{
    Refrain *_refrain;
    __weak IBOutlet NSButton *_btnMark;
}


-(void)setRefrain:(Refrain *)refrain;

@end

NS_ASSUME_NONNULL_END
