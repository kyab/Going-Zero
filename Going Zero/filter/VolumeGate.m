//
//  VolumeGate.m
//  Going Zero
//
//  Created by yoshioka on 2024/04/04.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "VolumeGate.h"

@implementation VolumeGate

-(id)init{
    self = [super init];
    _is_active = NO;
    _is_gate_open = YES;
    return self;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
//    if (!_is_active){
//        return;
//    }
//    
//    for (int i = 0; i < numSamples; i++){
//        if (_is_gate_open){
//            leftBuf[i] = 0;
//            rightBuf[i] = 0;
//        }
//    }
}

-(void)activate{
    _is_active = YES;
    _is_gate_open = NO;
}

-(void)deactivate{
    _is_active = NO;
    _is_gate_open = NO;
}

-(void)openGate{
    if (_is_active){
        _is_gate_open = YES;
    }
}

-(void)closeGate{
    if (_is_active){
        _is_gate_open = NO;
    }
}


@end
