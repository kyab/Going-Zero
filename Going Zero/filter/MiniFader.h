//
//  MiniFader.h
//  Going Zero
//
//  Created by kyab on 2021/06/01.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define FADE_SAMPLE_NUM 50  //around 1ms fade

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
