//
//  DJFilter.m
//  Anytime Scratch
//
//  Created by kyab on 2020/08/11.
//  Copyright © 2020 kyab. All rights reserved.
//

#import "DJFilter.h"
#include <math.h>

@implementation DJFilter

-(id)init;
{
    self = [super init];
    _lpf = [[LPF_IIR alloc] init];
    _hpf = [[HPF_IIR alloc] init];
    _faderIn = [[MiniFaderIn alloc] init];

    [self setFilterValue: 0.0];
    
    return self;
}

-(float)getFilterValue{
    return _v;
}

-(void)setFilterValue:(float)v{
//    NSLog(@"filter value is now %f", v);
//    if (fabsf(v - _v) >= 0.1){
//        [_faderIn startFadeIn];
//    }
    if (_v != 0.0f && _v != -0.0f ){
        if (v == 0.0f || v == -0.0f){
            [_faderIn startFadeIn];
        }
    }
    _v = v;
    v = v/1.3;
    
    
//    if (v < 0){
//        [_hpf setCutOffFrequency:150.0];
//        float fc = (1.0+v) * 3000 + 300;
//        NSLog(@"cutoff(LP) = %f", fc);
//        [_lpf setCutOffFrequency:fc];
//    }else{
//        [_lpf setCutOffFrequency:22000.0];
//        float fc = v * 5000 + 200;
//        NSLog(@"cutoff(HP) = %f", fc);
//        [_hpf setCutOffFrequency:fc];
//    }

    /*
     when 0 it goes 0
    
     when 1 it goes 22000
    
    */
    
    if (v < 0.0f){
        float fc = pow(1 + 1 + v, log2(22000));
        [_lpf setCutOffFrequency:fc];
        
        [_hpf setCutOffFrequency:1.0];
    }else{

        [_lpf setCutOffFrequency:22000];
        
        float fc =  pow( 1 + v, log2(22000));
        [_hpf setCutOffFrequency:fc];
    }
    
//    if (v == 0.0){
//        [_hpf setCutOffFrequency:100.0];
//        [_lpf setCutOffFrequency:20000.0];
//    }
}

-(void)processLeft:(float *)left right:(float *)right samples:(UInt32)sampleNum{
    if (_v == 0.0f || _v == -0.0f){
        [self reset];
//        return;
        
    }
    [_faderIn processLeft:left right:right samples:sampleNum];
    [_hpf processFromLeft:left right:right samples:sampleNum];
    [_lpf processFromLeft:left right:right samples:sampleNum];
    
}

-(void)reset{
    [_lpf reset];
    [_hpf reset];
}

@end
