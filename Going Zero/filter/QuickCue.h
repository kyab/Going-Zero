//
//  QuickCue.h
//  Going Zero
//
//  Created by kyab on 2021/06/15.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingBuffer.h"

NS_ASSUME_NONNULL_BEGIN

#define QUICKCUE_NUM 2

#define QUICKCUE_STATE_NONE 1
#define QUICKCUE_STATE_MARKED 2
#define QUICKCUE_STATE_PLAYING 3

@interface QuickCueUnit : NSObject{
    RingBuffer *_ring;
    UInt32 _state;
    UInt32 _cueFrame;
}

-(void)mark;
-(void)play;
-(void)clear;
-(void)exit;
-(UInt32)state;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;

@end

@interface QuickCue : NSObject{
    QuickCueUnit *_cueUnits[QUICKCUE_NUM];
}

-(void)mark:(UInt32)index;
-(void)play:(UInt32)index;
-(void)clear:(UInt32)index;

-(UInt32)state:(UInt32)state;
-(void)exit;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
@end



NS_ASSUME_NONNULL_END
