//
//  FlickerView.m
//  Going Zero
//
//  Created by koji on 2023/08/06.
//  Copyright © 2023 kyab. All rights reserved.
//

#import "FlickerView.h"

@implementation FlickerView

- (void)awakeFromNib{
    
//    _timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    _ratio = 0.0f;
    
}

-(void)setRatio:(float)ratio{
    _ratio = ratio;
}

//-(void)onTimer:(NSTimer *)timer{
//    [self setNeedsDisplay:YES];
//}

//- (void)setBeatTracker:(BeatTracker *)beatTracker{
//    _beatTracker = beatTracker;
//}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
//    if (!_beatTracker) return;
    
    [[NSColor blueColor] set];
    NSRectFill(dirtyRect);
    
//    float beatDuration = [_beatTracker beatDurationSec];
//    float sec = [_beatTracker estimatedNextBeatRelativeSec];
//
//    if (beatDuration < 0.1) return;
    
    NSRect rect = self.bounds;
    [[NSColor orangeColor] set];
    rect.size.width *= _ratio;
    NSRectFill(rect);
}

@end
