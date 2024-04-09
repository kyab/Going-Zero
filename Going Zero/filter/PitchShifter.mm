//
//  PitchShifter.m
//  Going Zero
//
//  Created by yoshioka on 2024/04/08.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "PitchShifter.h"
#include "signalsmith-stretch.h"

@implementation PitchShifter{
    signalsmith::stretch::SignalsmithStretch<float> _stretch;
}

-(id)init{
    self = [super init];
    _pitchShift = 0.0f;
    
    _stretch.presetDefault(2, 44100);
    _stretch.configure(2, 256, 256);
    _stretch.setTransposeSemitones(3.0);
    int block = _stretch.blockSamples();
    int interval = _stretch.intervalSamples();
    int inputLatency = _stretch.inputLatency();
    int outputLatency = _stretch.outputLatency();
    NSLog(@"Signalsmith-Stretch : block size = %d, interval = %d, inputLatency=%d, outputLatency=%d", block, interval, inputLatency, outputLatency);
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
