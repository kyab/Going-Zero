////
////  ConvolutionReverb.m
////  Going Zero
////
////  Created by kyab on 2021/12/19.
////  Copyright © 2021 kyab. All rights reserved.
////
//
//#import "ConvolutionReverb.h"
//#import <AudioToolbox/AudioFile.h>
//#import <AudioToolbox/ExtendedAudioFile.h>
//
//#import <complex>
//
//
//@implementation ConvolutionReverb
//-(id)init{
//    self = [super init];
//    _bypass = YES;
//    _ringIR = [[RingBuffer alloc] init];
//    [_ringIR setMinOffset:0];
//    
//    _ring = [[RingBuffer alloc] init];
//    [_ring setMinOffset:0];
//    
//    NSURL *url = [NSURL fileURLWithPath:@"/Users/koji/Downloads/IMreverbs/Narrow Bumpy Space.wav"];
//    ExtAudioFileRef ref = NULL;
//    OSStatus err = ExtAudioFileOpenURL((__bridge CFURLRef _Nonnull)(url), &ref);
//    
//    AudioStreamBasicDescription asbd;
//    asbd.mSampleRate = 44100.0;
//    asbd.mFormatID = kAudioFormatLinearPCM;
//    asbd.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
//    asbd.mBytesPerPacket = 4;
//    asbd.mFramesPerPacket = 1;
//    asbd.mBytesPerFrame = 4;
//    asbd.mChannelsPerFrame = 2;
//    asbd.mBitsPerChannel = 32;
//    err = ExtAudioFileSetProperty(ref, kExtAudioFileProperty_ClientDataFormat, sizeof(asbd), &asbd);
//    
//    AudioBufferList *bufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList) +  sizeof(AudioBuffer));
//    float *leftPrt = [_ringIR writePtrLeft];
//    float *rightPtr = [_ringIR writePtrRight];
//    
//    bufferList->mNumberBuffers = 2;
//    bufferList->mBuffers[0].mDataByteSize = sizeof(float) * [_ring frames];
//    bufferList->mBuffers[0].mNumberChannels = 1;
//    bufferList->mBuffers[0].mData = leftPrt;
//    bufferList->mBuffers[1].mDataByteSize = sizeof(float) * [_ring frames];
//    bufferList->mBuffers[1].mNumberChannels = 1;
//    bufferList->mBuffers[1].mData = rightPtr;
//    UInt32 readedSampleNum = [_ringIR frames];
//    
//    err = ExtAudioFileRead(ref, &readedSampleNum, bufferList );
//    NSLog(@"readed %u samples", readedSampleNum);
//    free(bufferList);
//    _reverbLen = readedSampleNum;
//    
//    _fftSize = 1024;
//    
//    
//    _fftInL = (fftw_complex *)malloc(_fftSize * sizeof(fftw_complex));
//    _fftInR = (fftw_complex *)malloc(_fftSize * sizeof(fftw_complex));
//    _fftOutL = (fftw_complex *)malloc(_fftSize * sizeof(fftw_complex));
//    _fftOutR = (fftw_complex *)malloc(_fftSize * sizeof(fftw_complex));
//    _ifftOutL = (fftw_complex *)malloc(_fftSize * sizeof(fftw_complex));
//    _ifftOutR = (fftw_complex *)malloc(_fftSize * sizeof(fftw_complex));
//    
//    memset(_fftInL, 0, _fftSize * sizeof(fftw_complex));
//    memset(_fftInR, 0, _fftSize * sizeof(fftw_complex));
//    memset(_fftOutL, 0, _fftSize * sizeof(fftw_complex));
//    memset(_fftOutR, 0, _fftSize * sizeof(fftw_complex));
//    memset(_ifftOutL, 0, _fftSize * sizeof(fftw_complex));
//    memset(_ifftOutR, 0, _fftSize * sizeof(fftw_complex));
//    
//    _biasL = (fftw_complex *)malloc(_fftSize * sizeof(fftw_complex));
//    _biasR = (fftw_complex *)malloc(_fftSize * sizeof(fftw_complex));
//    
//    
//    [self setupBias];
//    
//    return self;
//}
//
//-(void)setupBias{
//    
//    
//    UInt32 fftSize = 2048;
//    while(true){
//        if (fftSize < _reverbLen){
//            fftSize *= 2;
//        }else{
//            break;
//        }
//    }
//     
//    float *buffers[] = {[_ringIR startPtrLeft], [_ringIR startPtrRight]};
//    fftw_complex *biases[] = {_biasL, _biasR};
//    
//    for (int c = 0; c < 2; c++){
//     
//        fftw_complex *in, *out;
//        in = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * fftSize);
//        out = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * fftSize);
//        
//        float *pBuf = buffers[c];
//        for (int i = 0 ; i < fftSize; i++){
//            in[i][0] = pBuf[i];
//            in[i][1] = 0;
//        }
//
//        fftw_plan fft;
//        fft = fftw_plan_dft_1d(fftSize, in, out, FFTW_FORWARD, FFTW_ESTIMATE);
//        fftw_execute(fft);
//    
//        UInt32 step = fftSize / _fftSize;
//        for (int i =0; i < _fftSize; i++){
//
////            std::complex<double> sum;
////            std::complex<double> *comp = (std::complex<double> *)out[i*step];
////
////            for (int j = 0; j < step ; j++){
////                sum += comp[j];
////            }
////            sum /= step;
////
////            biases[c][i][0] = sum.real();
////            biases[c][i][1] = sum.imag();
//            
//            biases[c][i][0] = out[i*step][0];
//            biases[c][i][1] = out[i*step][1];
//            
//        }
//        
//    }
//}
//
//-(void)setBypass:(Boolean)bypass{
//    _bypass = bypass;
//}
//
////https://thewolfsound.com/fast-convolution-fft-based-overlap-add-overlap-save-partitioned/
//
//-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
//
//    if (_bypass){
//        float *leftDst = [_ring writePtrLeft];
//        float *rightDst = [_ring writePtrRight];
//        memset(leftDst, 0, numSamples * sizeof(float));
//        memset(rightDst, 0 , numSamples * sizeof(float));
//        [_ring advanceWritePtrSample:numSamples];
//        
//        return;
//    }
//
//    float *leftDst = [_ring writePtrLeft];
//    float *rightDst = [_ring writePtrRight];
//    memcpy(leftDst, leftBuf, numSamples * sizeof(float));
//    memcpy(rightDst, rightBuf, numSamples * sizeof(float));
//    [_ring advanceWritePtrSample:numSamples];
//    
//    float *starts[] = {[_ring writePtrLeft], [_ring writePtrRight]};
//    fftw_complex *ins[] = {_fftInL, _fftInR};
//    fftw_complex *outs[] = {_fftOutL, _fftOutR};
//    fftw_complex *iffts[] = {_ifftOutL, _ifftOutR};
//    float *dst[] = {leftBuf, rightBuf};
//    fftw_complex *biases[] = {_biasL, _biasR};
//    for (int c = 0; c < 2; c++){
//        fftw_complex *in, *out;
//        in = ins[c];
//        out = outs[c];
//        float *pBuf = starts[c] - _fftSize;
//        for (int i = 0 ; i < _fftSize; i++){
//            in[i][0] = pBuf[i];
//            in[i][1] = 0;
//        }
//        
//        fftw_plan fft;
//        fft = fftw_plan_dft_1d(_fftSize, in, out, FFTW_FORWARD, FFTW_ESTIMATE);
//        fftw_execute(fft);
//        
//        //multiply
//        std::complex<double> *d = (std::complex<double> *)out;
//        std::complex<double> *b = (std::complex<double> *)biases[c];
//        for (int i = 0; i < _fftSize; i++){
//            d[i] *= b[i];
//        }
//
//        fftw_complex *in2, *out2;
//        in2 = out;
//        out2 = iffts[c];
//        fftw_plan ifft;
//        ifft = fftw_plan_dft_1d(_fftSize, in2, out2, FFTW_BACKWARD, FFTW_ESTIMATE);
//        fftw_execute(ifft);
//        
//        for (int i = 0 ; i < _fftSize; i++){
//            out2[i][0] /= _fftSize;
//            out2[i][1] /= _fftSize;
//        }
//        
//        for (int i = 0; i < numSamples; i++){
//            dst[c][i] = out2[_fftSize - numSamples + i][0];
//        }
//
//    }
//    
//}
//
//-(void)processLeft2:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
//    
//    if (_bypass){
//        float *leftDst = [_ring writePtrLeft];
//        float *rightDst = [_ring writePtrRight];
//        memset(leftDst, 0, numSamples * sizeof(float));
//        memset(rightDst, 0 , numSamples * sizeof(float));
//        [_ring advanceWritePtrSample:numSamples];
//        
//        return;
//    }
//    
//    for(int i = 0 ; i < numSamples ; i++){
//        float *leftIR = [_ringIR readPtrLeft];
//        float *rightIR = [_ringIR readPtrRight];
//        
//        *[_ring writePtrLeft] = leftBuf[i];
//        *[_ring writePtrRight] = rightBuf[i];
//        
//        [_ring advanceWritePtrSample:1];
//        
//        for (int j = 0; j < 500; j++){
//            if (j == 0){
//                leftBuf[i] = leftIR[0] * leftBuf[i];
//                rightBuf[i] = rightIR[0] * rightBuf[i];
//            }else{
//                leftBuf[i] += leftIR[j] * [_ring writePtrLeft][-j];
//                rightBuf[i] += rightIR[j] * [_ring writePtrRight][-j];
//            }
//        }
//    }
//}
//
//@end
