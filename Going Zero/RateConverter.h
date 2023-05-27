//
//  RateConverter.h
//  Going Zero
//
//  Created by kyab on 2021/12/21.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RateConverter : NSObject

+(void)convertAtRateFromLeft:(float *)srcL right:(float *)srcR
                     leftDest:(float *)dstL rightDest:(float *)dstR
                    ToSamples:(UInt32)inNumberFrames
                         rate:(double)rate
              consumedFrames:(SInt32 *)consumed;

@end

NS_ASSUME_NONNULL_END
