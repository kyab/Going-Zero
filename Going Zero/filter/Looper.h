//
//  Looper.h
//  Going Zero
//
//  Created by kyab on 2021/06/04.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface Looper : NSObject{
    RingBuffer *_ring;
    UInt32 _state;
    UInt32 _duration;       //frame
    
}

-(void)markStart;
-(void)markEnd;
-(void)exit;
-(void)doHalf;
-(void)doQuater;
-(void)divide8;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;


@end

NS_ASSUME_NONNULL_END
