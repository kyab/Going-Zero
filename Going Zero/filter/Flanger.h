//
//  Flanger.h
//  Going Zero
//
//  Created by kyab on 2021/07/04.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"
#import "MiniFader.h"

NS_ASSUME_NONNULL_BEGIN

@interface Flanger : NSObject{
    RingBuffer *_ring;
    MiniFaderIn *_faderIn;
    
    int _n;
    
    float _depth;
    float _freq;
    
    Boolean _bypass;
}

-(void)setBypass:(Boolean)bypass;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;

-(void)setDepth:(float)depth;
-(void)setFreq:(float)freq;

@end

NS_ASSUME_NONNULL_END
