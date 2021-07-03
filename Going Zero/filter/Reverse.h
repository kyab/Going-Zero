//
//  Reverse.h
//  Going Zero
//
//  Created by kyab on 2021/06/13.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"
#import "MiniFader.h"

#define REVERSE_STATE_NORMAL   0
#define REVERSE_STATE_REVERSE  1

NS_ASSUME_NONNULL_BEGIN

@interface Reverse : NSObject{
    RingBuffer *_ring;
    UInt32 _state;
    MiniFaderIn *_faderIn;
    
    float _dryVolume;
    
}
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;

-(void)startReverse;
-(void)stopReverse;
-(void)setDryVolume:(float)dryVolume;
@end

NS_ASSUME_NONNULL_END
