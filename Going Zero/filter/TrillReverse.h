//
//  TrillReverce.h
//  Going Zero
//
//  Created by kyab on 2021/05/29.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"
#import "MiniFader.h"

NS_ASSUME_NONNULL_BEGIN

@interface TrillReverse : NSObject{
    RingBuffer *_ring;
    Boolean _bypass;
    UInt32 _count;
    Boolean _forward;
    float _durationSec;
    
    MiniFaderIn *_miniFadeIn;
    MiniFaderOut *_miniFadeOut;
}

-(void)setActive:(Boolean)active;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
-(void)setDurationSecond:(float)durationSecond;
@end

NS_ASSUME_NONNULL_END
