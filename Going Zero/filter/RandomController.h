//
//  RandomController.h
//  Going Zero
//
//  Created by kyab on 2021/12/06.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Random.h"

NS_ASSUME_NONNULL_BEGIN

@interface RandomController : NSViewController{
    Random *_random;
}

-(void)setRandom:(Random *)random;

@end

NS_ASSUME_NONNULL_END
