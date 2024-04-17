//
//  PitchShifter.h
//  Going Zero
//
//  Created by yoshioka on 2024/04/08.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PitchShifter : NSObject{
    float _pitchShift;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
-(void)processNonInplaceLeftIn:(float *)leftBufIn rightIn:(float *)rightBufIn leftOut:(float *)leftBufOut rightOut:(float *)rightBufOut samples:(UInt32)numSamples;
-(void)setPitchShift:(float)pitchShift;

@end

NS_ASSUME_NONNULL_END
