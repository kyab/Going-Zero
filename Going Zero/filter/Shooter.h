//
//  Shooter.h
//  Going Zero
//
//  Created by kyab on 2021/06/07.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"

NS_ASSUME_NONNULL_BEGIN

#define SHOOTER_STATE_NONE 0
#define SHOOTER_STATE_RECORDING 1
#define SHOOTER_STATE_READY 2

@interface Shooter : NSObject{
    RingBuffer *_ring;
    UInt32 _state;
    
    UInt32 _startFrame;
    UInt32 _length;
    
    NSMutableArray *_shots;
    
    float _pitch;
    float _pan;
}

-(void)recOrExit;
-(void)shoot;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
-(UInt32)state;
-(void)setPitch:(float)pitch;
-(float)pitch;
-(void)setPan:(float)pan;

@end

NS_ASSUME_NONNULL_END
