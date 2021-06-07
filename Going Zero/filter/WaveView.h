//
//  WaveView.h
//  Going Zero
//
//  Created by kyab on 2021/06/03.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RingBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface WaveView : NSView{
    RingBuffer *_ring;
    
    NSTimer *_timer;
}

- (void)setRingBuffer:(RingBuffer *)ring;



@end

NS_ASSUME_NONNULL_END
