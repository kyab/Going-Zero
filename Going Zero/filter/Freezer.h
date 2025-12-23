//
//  Freezer.h
//  Going Zero
//
//  Created by kyab on 2021/05/31.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "MiniFader.h"
#import "RingBuffer.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Freezer : NSObject{
    RingBuffer *_ring;
    Boolean _bypass;
    
    float *_startL;
    float *_startR;
    float *_currentL;
    float *_currentR;
    
    unsigned int _grainSize;
    
    MiniFaderIn *_miniFadeIn;
    MiniFaderOut *_miniFadeOut;
    
    // Fade transition for bypass switching
    Boolean _targetBypass;
    Boolean _isFadingOut;
    Boolean _isFadingIn;
    MiniFaderOut *_fadeOut;
    MiniFaderIn *_fadeIn;
    UInt32 _fadeOutCounter;
    UInt32 _fadeInCounter;
}

-(void)setActive:(Boolean)active;
-(void)setGrainSize:(unsigned int)grainSize;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;

@end

NS_ASSUME_NONNULL_END
