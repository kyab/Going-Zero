//
//  LookUp.h
//  Going Zero
//
//  Created by koji on 2023/05/24.
//  Copyright © 2023 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"

#define LOOKUP_STATE_NONE 0
#define LOOKUP_STATE_MARKING 1
#define LOOKUP_STATE_LOOPING 2
#define LOOKUP_STATE_LOOKUPPING 3

NS_ASSUME_NONNULL_BEGIN

@interface Lookup : NSObject {
    RingBuffer *_ring;
    
    UInt32 _duration;
    UInt32 _baseFrame;
    UInt32 _recordBaseFrame;
    double _playStartRatio;
    UInt32 _playStartFrame;
    UInt32 _state;
}

-(void)startMark;
-(void)startLooping;
-(void)startLookupping:(double)ratio;
-(void)stopLookupping;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSample;
-(UInt32)playFrameInBar;
-(UInt32)recordFrameInBar;
-(UInt32)barDuration;

@end

NS_ASSUME_NONNULL_END
