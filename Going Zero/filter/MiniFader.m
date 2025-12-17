//
//  MiniFader.m
//  Going Zero
//
//  Created by kyab on 2021/06/01.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "MiniFader.h"

@implementation MiniFaderIn

-(id)init{
    self = [super init];
    
    _count = FADE_SAMPLE_NUM;
    return self;
}

-(void)startFadeIn{
    _count = 0;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    for (int i = 0; i < numSamples; i++){
        if (_count < FADE_SAMPLE_NUM){
            float rate = _count / (float)FADE_SAMPLE_NUM;
            leftBuf[i] *= rate;
            rightBuf[i] *= rate;
            _count++;
        }
    }
}
@end

@implementation MiniFaderOut

-(id)init{
    self = [super init];
    
    _count = 0;
    return self;
}

-(void)startFadeOut{
    _count = FADE_SAMPLE_NUM;
}

-(void)startFadeOutWithSampleNum:(UInt32)sampleNum{
    _count = sampleNum;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    for (int i = 0; i < numSamples; i++){
        if (0 < _count){
            float rate = _count / (float)FADE_SAMPLE_NUM;
            leftBuf[i] *= rate;
            rightBuf[i] *= rate;
            
            _count--;
        }
    }
}

@end
