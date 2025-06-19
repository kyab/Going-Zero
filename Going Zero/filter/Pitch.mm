//
//  Pitch.m
//  Going Zero
//
//  Created by koji on 2025/06/18.
//  Copyright © 2025 kyab. All rights reserved.
//

#import "Pitch.h"

#import "TimePitch.h"

// Including external header with supressing warnings.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#include "signalsmith-stretch.h"
#pragma clang diagnostic pop

@implementation Pitch{
    signalsmith::stretch::SignalsmithStretch<float> _stretch;
}

-(id)init{
    
    self = [super init];
    
    _stretch.presetDefault(2, 44100);
    
    {
        int block = _stretch.blockSamples();
        int interval = _stretch.intervalSamples();
        int inputLatency = _stretch.inputLatency();
        int outputLatency = _stretch.outputLatency();
        NSLog(@"[Pitch] Signalsmith-Stretch(Default) : block size = %d, interval = %d, inputLatency=%d, outputLatency=%d", block, interval, inputLatency, outputLatency);
    }
    
    _pitchShift = 0.0f;
    
    return self;
}

-(void)setPitchShift:(float)pitchShift{
    _pitchShift = pitchShift;
    _stretch.setTransposeSemitones(_pitchShift);
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    if (fabs(_pitchShift) < 0.0001f) {
        return;
    }
        
    float *input[2];
    input[0] = leftBuf;
    input[1] = rightBuf;
    
    float *output[2];
    output[0] = (float *)malloc(sizeof(float) * numSamples);
    output[1] = (float *)malloc(sizeof(float) * numSamples);
    
    _stretch.process(input, numSamples, output, numSamples);
    
    memcpy(leftBuf, output[0], sizeof(float) * numSamples);
    memcpy(rightBuf, output[1], sizeof(float) * numSamples);
    
    free(output[0]);
    free(output[1]);
}

@end
