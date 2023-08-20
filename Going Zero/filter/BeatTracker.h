//
//  BeatTracker.h
//  Going Zero
//
//  Created by koji on 2023/08/04.
//  Copyright © 2023 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BeatTracker : NSObject{
    float _beatDuration;
}

-(float)pastBeatRelativeSec;
-(float)estimatedNextBeatRelativeSec;
-(float)beatDurationSec;
-(float)BPM;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
@end


NS_ASSUME_NONNULL_END
