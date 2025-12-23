//
//  MiniFader.h
//  Going Zero
//
//  Created by kyab on 2021/06/01.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define FADE_SAMPLE_NUM 50 // around 1ms fade

// Inline functions for single sample processing (low overhead)
static inline void inlineFadeInSingleSample(float *left, float *right,
                                            UInt32 *count) {
    if (*count < FADE_SAMPLE_NUM) {
        float rate = *count / (float)FADE_SAMPLE_NUM;
        *left *= rate;
        *right *= rate;
        (*count)++;
    }
}

static inline void inlineFadeOutSingleSample(float *left, float *right,
                                             UInt32 *count) {
    if (0 < *count) {
        float rate = *count / (float)FADE_SAMPLE_NUM;
        *left *= rate;
        *right *= rate;
        (*count)--;
    }
}

@interface MiniFaderIn : NSObject{
    UInt32 _count;
}

-(void)startFadeIn;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;

@end

@interface MiniFaderOut : NSObject{
    UInt32 _count;
}

-(void)startFadeOut;
-(void)startFadeOutWithSampleNum:(UInt32)sampleNum;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;

@end
NS_ASSUME_NONNULL_END
