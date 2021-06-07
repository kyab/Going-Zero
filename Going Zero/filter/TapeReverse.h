//
//  TapeReverse.h
//  Going Zero
//
//  Created by kyab on 2021/06/07.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"
NS_ASSUME_NONNULL_BEGIN

@interface TapeReverse : NSObject{
    RingBuffer *_ring;
    float _rate;
}

-(void)setRate:(float)rate;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;


@end

NS_ASSUME_NONNULL_END
