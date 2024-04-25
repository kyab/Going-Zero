//
//  PitchShifter.m
//  Going Zero
//
//  Created by yoshioka on 2024/04/08.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "PitchShifter.h"

// Including external header with supressing warnings.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#include "signalsmith-stretch.h"
#pragma clang diagnostic pop

@implementation PitchShifter{
    signalsmith::stretch::SignalsmithStretch<float> _stretch;
}

-(id)init{
    self = [super init];
    _pitchShift = 0.0f;
    _timeStretch = 1.0f;
    
    _stretch.presetDefault(2, 44100);
//    _stretch.configure(2, 256, 256);
    int block = _stretch.blockSamples();
    int interval = _stretch.intervalSamples();
    int inputLatency = _stretch.inputLatency();
    int outputLatency = _stretch.outputLatency();
    NSLog(@"Signalsmith-Stretch : block size = %d, interval = %d, inputLatency=%d, outputLatency=%d", block, interval, inputLatency, outputLatency);
    return self;
}

-(void)setPitchShift:(float)pitchShift{
    _pitchShift = pitchShift;
    _stretch.setTransposeSemitones(pitchShift);
}

-(void)setTimeStretch:(float)timeStretch{
    _timeStretch = timeStretch;
}

-(UInt32)latencyFrames{
    return _stretch.inputLatency() + _stretch.outputLatency();
}


-(void)feedLeft:(const float *)leftBufIn right:(float *)rightBufIn samples:(UInt32)numSamples{
    const float *input[2];
    input[0] = leftBufIn;
    input[1] = rightBufIn;
    
    float *output[2];
    output[0] = (float *)malloc(sizeof(float) * numSamples);
    output[1] = (float *)malloc(sizeof(float) * numSamples);
    
    _stretch.process(input, numSamples, output, numSamples);
    
    free(output[0]);
    free(output[1]);
}


-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
        
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

-(void)processNonInplaceLeftIn:(const float *)leftBufIn rightIn:(const float *)rightBufIn leftOut:(float *)leftBufOut rightOut:(float *)rightBufOut samples:(UInt32)numSamples{
    
    const float *input[2];
    input[0] = leftBufIn;
    input[1] = rightBufIn;
    
    float *output[2];
    output[0] = leftBufOut;
    output[1] = rightBufOut;
    
    _stretch.process(input, numSamples, output, numSamples);
}

-(UInt32)processNonInplaceWithStretchLeftIn:(const float *)leftBufIn rightIn:(const float *)rightBufIn leftOut:(float *)leftBufOut rightOut:(float *)rightBufOut outNumSamples:(UInt32)outNumSamples{
        
    const float *input[2];
    input[0] = leftBufIn;
    input[1] = rightBufIn;
    
    float *output[2];
    output[0] = leftBufOut;
    output[1] = rightBufOut;

    UInt32 consumedInSamples = _timeStretch * outNumSamples;
    _stretch.process(input, consumedInSamples, output, outNumSamples);
    
    return consumedInSamples;
}




@end
