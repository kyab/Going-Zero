//
//  BeatTrackerController.m
//  Going Zero
//
//  Created by koji on 2023/08/06.
//  Copyright © 2023 kyab. All rights reserved.
//

#import "BeatTrackerController.h"

@interface BeatTrackerController ()

@end

@implementation BeatTrackerController

- (void)viewDidLoad {
    [super viewDidLoad];
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)onTimer:(NSTimer *)timer{
    if (_beatTracker){
        float ratio = [_beatTracker estimatedNextBeatRelativeSec] / [_beatTracker beatDurationSec];
        
        [_beatView setRatio:ratio];
        [_beatView setNeedsDisplay:YES];
        
        float bpm = [_beatTracker BPM];
        [_lblBPM setStringValue:[NSString stringWithFormat:@"%.02f", bpm]];
    }
}


-(void)setBeatTracker:(BeatTracker *)beatTracker{
    _beatTracker = beatTracker;
}

@end
