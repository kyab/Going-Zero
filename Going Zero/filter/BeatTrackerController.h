//
//  BeatTrackerController.h
//  Going Zero
//
//  Created by koji on 2023/08/06.
//  Copyright © 2023 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BeatTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface BeatTrackerController : NSViewController{
    
    __weak IBOutlet NSTextField *_lblBPM;
    BeatTracker *_beatTracker;
}

-(void)setBeatTracker:(BeatTracker *)beatTracker;

@end

NS_ASSUME_NONNULL_END
