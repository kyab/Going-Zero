//
//  VocalRefrain.h
//  Going Zero
//
//  Created by kyab on 2021/06/12.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"
#include <dispatch/dispatch.h>

#define VOCALREFRAIN_STATE_NONE 0
#define VOCALREFRAIN_STATE_MARKING 1
#define VOCALREFRAIN_STATE_REFRAINING 2

NS_ASSUME_NONNULL_BEGIN

@interface VocalRefrain : NSObject{
    RingBuffer *_ring;
    RingBuffer *_vocalRing;
    
    UInt32 _state;
    UInt32 _startFrame;
    UInt32 _frames;
    
    float _volume;
    float _pan;
    
    dispatch_queue_t _dq;

}

-(void)startMark;
-(void)startRefrain;
-(UInt32)state;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
-(void)exit;

-(void)setPan:(float)pan;

@end

NS_ASSUME_NONNULL_END
