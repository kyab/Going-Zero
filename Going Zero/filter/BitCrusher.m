//
//  BitCrusher.m
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "BitCrusher.h"

@implementation BitCrusher

-(id)init{
    self = [super init];
    _bypass = YES;
    
    return self;
}

-(void)setActive:(Boolean)active{
    if (active){
        _bypass = NO;
    }else{
        _bypass = YES;
    }
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    if (_bypass) return;
    
    int factor = 16;
    
    for(int i = 0; i < numSamples; i=i+8){
        float before = leftBuf[i];
        float pre = before * factor;
        pre += rand() / (RAND_MAX+1) * factor;
        pre = (SInt32)round(pre);
        pre = pre / factor;
        
        for ( int j = 0; j < 8; j++){
            leftBuf[i + j] = pre;
        }
        
        before = rightBuf[i];
        pre = before * factor;
        pre += rand() / (RAND_MAX+1) * factor;
        pre = (SInt32)round(pre);
        pre = pre / factor;
        
        for ( int j = 0; j < 8; j++){
            rightBuf[i + j] = pre;
        }
    }
    
}

@end
