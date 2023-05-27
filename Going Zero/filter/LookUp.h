//
//  LookUp.h
//  Going Zero
//
//  Created by koji on 2023/05/24.
//  Copyright © 2023 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface LookUp : NSObject {
    RingBuffer *_ring;
    
    UInt32 _duration;
}

-(void)startMark;
-(void)startLooping;


@end

NS_ASSUME_NONNULL_END
