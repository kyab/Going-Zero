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
    float _timeStretch;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
-(void)processNonInplaceLeftIn:(const float *)leftBufIn rightIn:(const float *)rightBufIn leftOut:(float *)leftBufOut rightOut:(float *)rightBufOut samples:(UInt32)numSamples;
-(void)feedLeft:(const float *)leftBufIn right:(float *)rightBufIn samples:(UInt32)numSamples;
-(void)setPitchShift:(float)pitchShift;
-(void)setTimeStretch:(float)timeStretch;
-(UInt32)latencyFrames;

@end

NS_ASSUME_NONNULL_END
