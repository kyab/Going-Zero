//
//  Melodizer.mm
//  Going Zero
//
//  Created by koji on 2026/08/24.
//  Copyright © 2026 kyab. All rights reserved.
//

#import "Melodizer.h"

// Including external header with supressing warnings.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#include "signalsmith-stretch.h"
#pragma clang diagnostic pop

@implementation Melodizer{
    signalsmith::stretch::SignalsmithStretch<float> _stretch;
}

-(id)init{
    
    self = [super init];

    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    
    _stretch.configure(2, 1024, 256);   // smaller block size for smaller latency.
    _stretch.configure(2, 2048, 512);    //smaller block size for smaller latency.
   {
        int block = _stretch.blockSamples();
        int interval = _stretch.intervalSamples();
        int inputLatency = _stretch.inputLatency();
        int outputLatency = _stretch.outputLatency();
        NSLog(@"[Melodizer] Signalsmith-Stretch : block size = %d, interval = %d, inputLatency=%d, outputLatency=%d", block, interval, inputLatency, outputLatency);
    }
    _isActive = YES;
    return self;
}

-(void)setTranspose:(float)pitchShift{
    _pitchShift = pitchShift;
    NSLog(@"Melodizer: setTranspose:%f", _pitchShift);
    _stretch.setTransposeSemitones(_pitchShift ,8000/44100.0);

}
-(void)stopTranspose{
    _pitchShift = 0.0f;
    _stretch.setTransposeSemitones(0.0, 8000/44100.0);
}


-(void)setActive:(BOOL)active{
    _stretch.reset();
    _isActive = active;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{

    if (!_isActive){
        return;
    }
        
    //use ring as temp buffer
    float *dstL = [_ring writePtrLeft];
    float *dstR = [_ring writePtrRight];
    memcpy(dstL, leftBuf, numSamples * sizeof(float));
    memcpy(dstR, rightBuf, numSamples * sizeof(float));    
    
    const float *input[2];
    input[0] = dstL;
    input[1] = dstR;
    
    float *output[2];
    output[0] = leftBuf;
    output[1] = rightBuf;
    
    _stretch.process(input, numSamples, output, numSamples);
    [_ring advanceWritePtrSample:numSamples];
}

@end
