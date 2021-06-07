//
//  BitCrasher.h
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface BitCrasher : NSObject{
    Boolean _bypass;
}

-(void)setActive:(Boolean)active;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;


@end

NS_ASSUME_NONNULL_END
