//
//  RingView.h
//  MyPlaythrough
//
//  Created by kyab on 2017/05/25.
//  Copyright © 2017年 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RingBuffer.h"

@interface RingView : NSView{
    RingBuffer *_ringBuffer;
}

-(void)setRingBuffer:(RingBuffer *)ring;



@end
