//
//  VolumeGate.h
//  Going Zero
//
//  Created by yoshioka on 2024/04/04.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VolumeGate : NSObject{
    Boolean _is_active;
    Boolean _is_gate_open;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
-(void)activate;
-(void)deactivate;
-(void)openGate;
-(void)closeGate;

@end

NS_ASSUME_NONNULL_END
