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
}

-(void)setLooper:(Looper *)looper;

@end

NS_ASSUME_NONNULL_END
