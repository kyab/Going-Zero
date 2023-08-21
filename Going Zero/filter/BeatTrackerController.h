//
//  BeatTrackerController.h
//  Going Zero
//
//  Created by koji on 2023/08/06.
//  Copyright © 2023 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BeatTracker.h"
#import "FlickerView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BeatTrackerController : NSViewController{
    
    __weak IBOutlet NSTextField *_lblBPM;
    BeatTracker *_beatTracker;
    __weak IBOutlet FlickerView *_flickerView;
    NSTimer *_timer;
}

-(void)setBeatTracker:(BeatTracker *)beatTracker;

@end

NS_ASSUME_NONNULL_END
