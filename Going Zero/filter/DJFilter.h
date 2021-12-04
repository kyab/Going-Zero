//
//  DJFilter.h
//  Anytime Scratch
//
//  Created by kyab on 2020/08/11.
//  Copyright © 2020 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPF_IIR.h"
#import "HPF_IIR.h"
#import "MiniFader.h"

NS_ASSUME_NONNULL_BEGIN

@interface DJFilter : NSObject{
    LPF_IIR *_lpf;
    HPF_IIR *_hpf;
    MiniFaderIn *_faderIn;
    float _v;
}

@property (nonatomic, setter = setFilterValue:, getter=getFilterValue) float filterValue;

-(void)setFilterValue:(float)v;
-(float)getFilterValue;
-(void)processLeft:(float *)left right:(float *)right samples:(UInt32)sampleNum;
-(void)reset;

@end

NS_ASSUME_NONNULL_END
