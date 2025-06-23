//
//  Pitch.h
//  Going Zero
//
//  Created by koji on 2025/06/18.
//  Copyright © 2025 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Pitch : NSObject {
    float _pitchShift;
}

-(void)setPitchShift:(float)pitchShift;
-(float)getPitchShift;
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples;
@end

NS_ASSUME_NONNULL_END
