//
//  VocalRefrain.m
//  Going Zero
//
//  Created by kyab on 2021/06/12.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "VocalRefrain.h"
#include "spleeter/spleeter.h"
#include "spleeter_filter/filter.h"
#include <vector>

#define SPLEET_SAMPLE_NUM 44100
#define SPLEET_PREFIX_SAMPLE_NUM 44100

static spleeter::Filter g_filter(spleeter::TwoStems);

@implementation VocalRefrain


-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    
    _volume = 2.0;
    _pan = 0.0;
    
    _vocalRing = [[RingBuffer alloc] init];
    [_vocalRing setMinOffset:0];
    _state = VOCALREFRAIN_STATE_NONE;
    
    [self initSpleeter];
    
    _dq = dispatch_queue_create("spleeter", DISPATCH_QUEUE_SERIAL);
    
    //    https://stackoverflow.com/questions/17690740/create-a-high-priority-serial-dispatch-queue-with-gcd/17690878
    dispatch_set_target_queue(_dq, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    
    return self;
}

-(void)initSpleeter{
    std::error_code err;
    NSLog(@"Initializing spleeter");
    
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    spleeter::Initialize(
                         std::string(resourcePath.UTF8String),{spleeter::TwoStems}, err);
    NSLog(@"spleeter Initialize err = %d", err.value());
    
    //split something for warm up.
    NSLog(@"First Split");
    std::vector<float> fragment(22050*2);
    spleeter::Waveform vocals, drums, bass, piano, other;
    auto source = Eigen::Map<spleeter::Waveform>(fragment.data(),
                                                    2, fragment.size()/2);
    spleeter::Split(source, &vocals, &other, err);
    NSLog(@"First split error = %d", err.value());

    
}


-(void)startMark{
    _state = VOCALREFRAIN_STATE_MARKING;
    _startFrame = 0;
}

-(void)startRefrain{
    _state = VOCALREFRAIN_STATE_REFRAINING;
}

-(UInt32)state{
    return _state;
}

-(void)exit{
    _state = VOCALREFRAIN_STATE_NONE;
    [_ring reset];
    [_vocalRing reset];
}

-(void)setPan:(float)pan{
    _pan = pan;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    switch(_state){
        case VOCALREFRAIN_STATE_NONE:
            break;
        case VOCALREFRAIN_STATE_MARKING:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            memcpy(dstL, leftBuf, numSamples * sizeof(float));
            memcpy(dstR, rightBuf, numSamples * sizeof(float));
            [_ring advanceWritePtrSample:numSamples];
            
            [self spleetRing];
            
            
        }
            break;
        case VOCALREFRAIN_STATE_REFRAINING:
        {
            float *dstL = [_ring writePtrLeft];
            float *dstR = [_ring writePtrRight];
            memcpy(dstL, leftBuf, numSamples * sizeof(float));
            memcpy(dstR, rightBuf, numSamples * sizeof(float));
            [_ring advanceWritePtrSample:numSamples];
            
            [self spleetRing];
            
            
            float *srcL = [_vocalRing readPtrLeft];
            float *srcR = [_vocalRing readPtrRight];
            
            float volL = 1.0;
            float volR = 1.0;
            if (_pan > 0.0){
                volL = 1.0 - _pan;
            }else{
                volR = 1.0 + _pan;
            }
            
            for(int i = 0; i < numSamples; i++){
                leftBuf[i] += srcL[i] * _volume * volL;
                rightBuf[i] += srcR[i] * _volume * volR;
            }
            
            [_vocalRing advanceReadPtrSample:numSamples];
        }
            break;
        default:
            break;
    }
}


-(void)spleetRing{
    
    if ([_ring readWriteOffset] >= SPLEET_SAMPLE_NUM){
        
        float *leftSrc = [self->_ring readPtrLeft];
        float *rightSrc = [self->_ring readPtrRight];
        [self->_ring advanceReadPtrSample:SPLEET_SAMPLE_NUM];
        
        
        dispatch_async(_dq, ^{

            //make interleaved buffer
            std::vector<float>fragment(SPLEET_PREFIX_SAMPLE_NUM*2 + SPLEET_SAMPLE_NUM*2);
            for(int i = 0; i < SPLEET_SAMPLE_NUM; i++){
                fragment[SPLEET_PREFIX_SAMPLE_NUM*2 + i*2] = leftSrc[i];
                fragment[SPLEET_PREFIX_SAMPLE_NUM*2 + i*2+1] = rightSrc[i];
            }
            
            //lets spleet it to two stems
            spleeter::Waveform vocals, other;
            auto source = Eigen::Map<spleeter::Waveform>(fragment.data(),2,fragment.size()/2);
            std::error_code err;
            spleeter::Split(source, &vocals, &other, err);
            if (err.value() != 0){
                NSLog(@"Split error = %d", err.value());
            }
            
            //now get back to non-interleaved buffer
            std::vector<float> left(SPLEET_SAMPLE_NUM);
            std::vector<float> right(SPLEET_SAMPLE_NUM);
            
            for(int i = 0; i < SPLEET_SAMPLE_NUM; i++){
                left[i] = *(vocals.data() + SPLEET_PREFIX_SAMPLE_NUM*2 + i*2);
                right[i] = *(vocals.data() + SPLEET_PREFIX_SAMPLE_NUM*2 + i*2+1);
            }
            
            //push it into vocal ring
            memcpy([self->_vocalRing writePtrLeft], left.data(), SPLEET_SAMPLE_NUM * sizeof(float));
            memcpy([self->_vocalRing writePtrRight], right.data(), SPLEET_SAMPLE_NUM * sizeof(float));
            [self->_vocalRing advanceWritePtrSample:SPLEET_SAMPLE_NUM];
            
            
            //cancel if state is already changed to none.
            if(self->_state == VOCALREFRAIN_STATE_NONE){
                [self->_ring reset];
                [self->_vocalRing reset];
            }
            
        });
    }
}

//-(void)spleetRing2{
//
//    if ([_ring readWriteOffset] >= SPLEET_SAMPLE_NUM){
//
//        float *leftSrc = [self->_ring readPtrLeft];
//        float *rightSrc = [self->_ring readPtrRight];
//        [self->_ring advanceReadPtrSample:SPLEET_SAMPLE_NUM];
//
//
//        dispatch_async(_dq, ^{
//
//            //make interleaved buffer
//            std::vector<float>fragment(SPLEET_PREFIX_SAMPLE_NUM*2 + SPLEET_SAMPLE_NUM*2);
//            for(int i = 0; i < SPLEET_SAMPLE_NUM; i++){
//                fragment[SPLEET_PREFIX_SAMPLE_NUM*2 + i*2] = leftSrc[i];
//                fragment[SPLEET_PREFIX_SAMPLE_NUM*2 + i*2+1] = rightSrc[i];
//            }
//
//            //lets spleet it to two stems
//
//            spleeter::Waveform vocals, other;
//            auto source = Eigen::Map<spleeter::Waveform>(fragment.data(),2,fragment.size()/2);
//            std::error_code err;
//            spleeter::Split(source, &vocals, &other, err);
//            if (err.value() != 0){
//                NSLog(@"Split error = %d", err.value());
//            }
//
//            //now get back to non-interleaved buffer
//            std::vector<float> left(SPLEET_SAMPLE_NUM);
//            std::vector<float> right(SPLEET_SAMPLE_NUM);
//
//            for(int i = 0; i < SPLEET_SAMPLE_NUM; i++){
//                left[i] = *(vocals.data() + SPLEET_PREFIX_SAMPLE_NUM*2 + i*2);
//                right[i] = *(vocals.data() + SPLEET_PREFIX_SAMPLE_NUM*2 + i*2+1);
//            }
//
//            //push it into vocal ring
//            memcpy([self->_vocalRing writePtrLeft], left.data(), SPLEET_SAMPLE_NUM * sizeof(float));
//            memcpy([self->_vocalRing writePtrRight], right.data(), SPLEET_SAMPLE_NUM * sizeof(float));
//            [self->_vocalRing advanceWritePtrSample:SPLEET_SAMPLE_NUM];
//
//
//            //cancel if state is already changed to none.
//            if(self->_state == VOCALREFRAIN_STATE_NONE){
//                [self->_ring reset];
//                [self->_vocalRing reset];
//            }
//
//        });
//    }
//}

@end
