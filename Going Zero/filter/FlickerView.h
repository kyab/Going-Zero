//
//  FlickerView.h
//  Going Zero
//
//  Created by koji on 2023/08/06.
//  Copyright © 2023 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BeatTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlickerView : NSView{
    BeatTracker *_beatTracker;
    NSTimer *_timer;
}

-(void)setBeatTracker:(BeatTracker *)beatTracker;

@end

NS_ASSUME_NONNULL_END
