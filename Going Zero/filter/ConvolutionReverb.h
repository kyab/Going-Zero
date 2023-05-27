//
//  ConvolutionReverb.h
//  Going Zero
//
//  Created by kyab on 2021/12/19.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"
#import "fftw3.h"
NS_ASSUME_NONNULL_BEGIN


@interface ConvolutionReverb : NSObject{
    RingBuffer *_ringIR;
    RingBuffer *_ring;
    Boolean _bypass;
    UInt32 _reverbLen;
    UInt32 _fftSize;
    
    fftw_complex *_biasL;
    fftw_complex *_biasR;
    fftw_complex *_fftInL, *_fftInR;
    fftw_complex *_fftOutL, *_fftOutR;
    fftw_complex *_ifftOutL, *_ifftOutR;
    
}

-(void)setBypass:(Boolean)bypass;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;

@end

NS_ASSUME_NONNULL_END
