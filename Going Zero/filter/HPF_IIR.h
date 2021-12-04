//
//  HPF_IIR.h
//  Anytime Scratch
//
//  Created by kyab on 2020/08/11.
//  Copyright © 2020 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface HPF_IIR : NSObject{
    RingBuffer *_ringPre;
    RingBuffer *_ringPost;
    
    float _fc;
}

-(void)setCutOffFrequency:(float)fc;
-(void)processFromLeft:(float *)left right:(float *)right samples:(UInt32)sampleNum;
-(void)reset;
@end

NS_ASSUME_NONNULL_END
