//
//  Bender.h
//  Going Zero
//
//  Created by kyab on 2021/05/30.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"
#import "MiniFader.h"

NS_ASSUME_NONNULL_BEGIN

@interface Bender : NSObject{
    RingBuffer *_ring;
    float _rate;
    Boolean _bypass;
    MiniFaderIn *_miniFadeIn;
    Boolean _bounce;
}
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
-(void)setRate:(float)rate;
-(void)resetRate;
-(Boolean)isCatchingUp;
-(void)setActive:(Boolean)active;
-(void)setBounce:(Boolean)bounce;
-(Boolean)bounce;



@end

NS_ASSUME_NONNULL_END
