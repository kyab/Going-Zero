//
//  PitchShifter.m
//  Going Zero
//
//  Created by yoshioka on 2024/04/08.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "PitchShifter.h"

@implementation PitchShifter

-(id)init{
    self = [super init];
    _pitchShift = 0.0f;
    return self;
}

-(void)setPitchShift:(float)pitchShift{
    _pitchShift = pitchShift;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    if (_pitchShift == 0.0f){
        return;
    }
}

@end
