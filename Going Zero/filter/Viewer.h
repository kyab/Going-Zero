//
//  Viewer.h
//  Going Zero
//
//  Created by kyab on 2021/06/03.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface Viewer : NSObject{
    RingBuffer *_ring;
    Boolean _enabled;
    
}

-(RingBuffer *)ring;
-(void)setExternalRing:(RingBuffer *)ring;
-(void)setEnabled:(Boolean)enabled;
-(Boolean)isEnabled;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;


@end

NS_ASSUME_NONNULL_END
