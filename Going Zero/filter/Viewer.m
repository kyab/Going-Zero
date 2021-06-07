//
//  Viewer.m
//  Going Zero
//
//  Created by kyab on 2021/06/03.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "Viewer.h"

@implementation Viewer

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    
    return self;
}

-(RingBuffer *)ring{
    return _ring;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    float *dstL = [_ring writePtrLeft];
    float *dstR = [_ring writePtrRight];
    
    memcpy(dstL, leftBuf, numSamples*sizeof(float));
    memcpy(dstR, rightBuf, numSamples*sizeof(float));
    
    [_ring advanceWritePtrSample:numSamples];

}

@end
