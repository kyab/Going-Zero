//
//  TurnTableEx.h
//  Going Zero
//
//  Created by kyab on 2021/06/18.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface TurnTableEx : NSObject{
    RingBuffer *_ring;
    float _speedRate;
    float _nextSpeedRate;
}

-(void)reset;
-(void)setSpeedRate:(float)speedRate;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;

@end

NS_ASSUME_NONNULL_END
