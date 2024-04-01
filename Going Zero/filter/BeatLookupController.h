//
//  BeatLookupController.h
//  Going Zero
//
//  Created by yoshioka on 2024/01/31.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BeatLookup.h"
#import "BeatlookupWaveView.h"
#import "JugglingTouchView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BeatLookupController : NSViewController <JugglingTouchViewDelegate>{
    BeatLookup *_beatLookup;
    
    __weak IBOutlet BeatlookupWaveView *_beatLookupWaveView;
    __weak IBOutlet JugglingTouchView *_jugglingTouchView;
    __weak IBOutlet NSButton *_chkFinely;
}

-(void)setBeatLookup:(BeatLookup *)beatLookup;

@end

NS_ASSUME_NONNULL_END
