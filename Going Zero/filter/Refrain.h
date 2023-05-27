//
//  Refrain.h
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"

#define REFRAIN_STATE_NONE 0
#define REFRAIN_STATE_MARKING 1
#define REFRAIN_STATE_REFRAINING 2

NS_ASSUME_NONNULL_BEGIN

@interface Refrain : NSObject{
    RingBuffer *_ring;
    UInt32 _state;
    UInt32 _startFrame;
    UInt32 _frames;
    
    float _pan;
    float _volume;
}

-(void)startMark;
-(void)startRefrain;
-(UInt32)state;
-(void)setPan:(float)pan;
-(void)setVolume:(float)volume;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
-(void)exit;

@end

NS_ASSUME_NONNULL_END
