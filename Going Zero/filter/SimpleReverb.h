//
//  SimpleReverb.h
//  Going Zero
//
//  Created by kyab on 2021/12/14.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface SimpleReverb : NSObject{
    RingBuffer *_ringY;
    Boolean _bypass;
}

-(void)setBypass:(Boolean)bypass;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
@end

NS_ASSUME_NONNULL_END
