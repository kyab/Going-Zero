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

NS_ASSUME_NONNULL_BEGIN

@interface LookUp : NSObject {
    RingBuffer *_ring;
    
    UInt32 _duration;
    UInt32 _state;
}

-(void)startMark;
-(void)startLooping;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSample;

@end

NS_ASSUME_NONNULL_END
