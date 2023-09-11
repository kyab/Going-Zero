//
//  Random.h
//  Going Zero
//
//  Created by kyab on 2021/12/06.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"
#import "BeatTracker.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RandomProtocol <NSObject>
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
@end

@interface RandomReverse : NSObject<RandomProtocol>{
    float *_leftPtr;
    float *_rightPtr;
    UInt32 _length;
    SInt32 _currentFrame;
}
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
@end

@interface RandomAsis : NSObject<RandomProtocol>{
    float *_leftPtr;
    float *_rightPtr;
    SInt32 _currentFrame;
}
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
@end

@interface RandomFreeze : NSObject<RandomProtocol>{
    float *_leftPtr;
    float *_rightPtr;
    SInt32 _currentFrame;
    UInt32 _grainSize;
}
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
@end

@interface RandomTapeStop : NSObject<RandomProtocol>{
    float *_leftPtr;
    float *_rightPtr;
    UInt32 _length;
    SInt32 _currentFrame;
    float _rate;
}
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
@end

@interface RandomTapeStart : NSObject<RandomProtocol>{
    float *_leftPtr;
    float *_rightPtr;
    UInt32 _length;
    SInt32 _currentFrame;
    float _rate;
}
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
@end

@interface Random : NSObject{
    Boolean _bypass;
    RingBuffer *_ring;
//    float _bpm;
    id<RandomProtocol> _filter;
    UInt32 _totalLength;
    UInt32 _sectionLength;
    UInt32 _currentSection;
    UInt32 _currentFrame;
    BeatTracker *_beatTracker;
}

-(void)start;
-(void)setBeatTracker:(BeatTracker *)beatTracker;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
    
@end

NS_ASSUME_NONNULL_END
