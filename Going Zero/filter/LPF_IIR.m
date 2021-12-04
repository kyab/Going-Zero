//
//  LPF_IIR.m
//  Anytime Scratch
//
//  Created by kyab on 2020/08/08.
//  Copyright © 2020 kyab. All rights reserved.
//

#import "LPF_IIR.h"
#import "RingBuffer.h"
#include <math.h>

@implementation LPF_IIR

-(id)init;
{
    self = [super init];
    _ringPre = [[RingBuffer alloc] init];
    _ringPost = [[RingBuffer alloc] init];
    
    _fc = 22000.0;
    
    return self;
}

void IIR_LPF(float fc, float Q, float *a, float *b){
    fc = tan(M_PI*fc)/(2.0*M_PI);
    
    a[0] = 1.0 + 2.0*M_PI*fc/Q + 4.0*M_PI*M_PI*fc*fc;
    a[1] = (8.0*M_PI*M_PI*fc*fc-2.0)/a[0];
    a[2] = (1.0-2.0*M_PI*fc/Q + 4.0*M_PI*M_PI*fc*fc)/a[0];
    b[0] = 4.0*M_PI*M_PI*fc*fc/a[0];
    b[1] = 8.0*M_PI*M_PI*fc*fc/a[0];
    b[2] = 4.0*M_PI*M_PI*fc*fc/a[0];
    
    a[0] = 1.0;
    
}

- (void)setCutOffFrequency:(float)fc{
    _fc = fc;
}

- (void)processFromLeft:(float *)leftPtr right:(float *)rightPtr samples:(UInt32)sampleNum{
    
    int fs = 44100;
    
    float fc = _fc / fs;
//    float Q = 1.0/sqrt(2.0);
    float Q = 5.0;
    int I = 2;
    int J = 2;
    
    float a[3];
    float b[3];
    
    float *leftPre = [_ringPre writePtrLeft];
    float *rightPre = [_ringPre writePtrRight];
    memcpy(leftPre, leftPtr, sizeof(float) * sampleNum);
    memcpy(rightPre, rightPtr, sizeof(float) * sampleNum);
    
    [_ringPre advanceWritePtrSample:sampleNum];
    
    float *leftPost = [_ringPost writePtrLeft];
    float *rightPost = [_ringPost writePtrRight];
    
    IIR_LPF(fc, Q, a, b);
    
    for (int n = 0; n < sampleNum; n++){
        leftPtr[n] = 0.0;
        rightPtr[n] = 0.0;
        for (int m = 0; m <=J; m++){
            leftPtr[n] += b[m]*leftPre[n-m];
            rightPtr[n] += b[m]*rightPre[n-m];
        }
        
        for (int m=1;m <= I; m++){
            leftPtr[n] += -a[m]*leftPost[n-m];
            rightPtr[n] += -a[m]*rightPost[n-m];
        }
        
        leftPost[n] = leftPtr[n];
        rightPost[n] = rightPtr[n];
    }
    [_ringPost advanceWritePtrSample:sampleNum];
}

-(void)reset{
    [_ringPre reset];
    [_ringPost reset];
}

@end
