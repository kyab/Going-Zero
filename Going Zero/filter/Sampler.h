//
//  Sampler.h
//  Going Zero
//
//  Created by kyab on 2021/06/04.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"

#define SAMPLER_STATE_READYRECORD 0
#define SAMPLER_STATE_RECORDING   1
#define SAMPLER_STATE_READYPLAY   2
#define SAMPLER_STATE_PLAYING     3

NS_ASSUME_NONNULL_BEGIN

@interface Sampler : NSObject{
    RingBuffer *_ring;
    UInt32 _state;
    UInt32 _startFrame;
    UInt32 _frames;     //loop length
    
    float _pan;
}

-(UInt32)state;
-(void)gotoNextState;
-(void)clear;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
-(void)setPan:(float)pan;

@end

NS_ASSUME_NONNULL_END
