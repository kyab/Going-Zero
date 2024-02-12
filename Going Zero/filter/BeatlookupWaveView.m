//
//  BeatlookupWaveView.m
//  Going Zero
//
//  Created by yoshioka on 2024/01/31.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "BeatlookupWaveView.h"

@implementation BeatlookupWaveView

-(void)awakeFromNib{
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

-(void)setBeatLookup:(BeatLookup *)beatLookup{
    _beatLookup = beatLookup;
}

-(void)onTimer:(NSTimer *)timer{
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    [[NSColor blackColor] set];
    NSRectFill(self.bounds);
    
    if (!_beatLookup) {
        return;
    }
    
    if ([_beatLookup barFrameNum] == 0){
        return;
    }
    
    CGFloat w = self.frame.size.width;
    CGFloat h = self.frame.size.height;
        
    UInt32 barFrameStart = [_beatLookup barFrameStart];
    RingBuffer *ring = [_beatLookup ring];
    CGFloat pixelsPerFrame = w / (2 * [_beatLookup barFrameNum]);
    NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(0,h/2)];
    [line lineToPoint:NSMakePoint(w,h/2)];
    [[NSColor orangeColor] set];

    SInt32 drawStartFrame = barFrameStart;
    if (barFrameStart > [ring recordFrame]){
        drawStartFrame -= [ring frames];
    }
    
    NSLog(@"drawStartFrame = %d, barFrameNum = %u, recordFrame = %u pixelsPerFrame = %f", drawStartFrame, [_beatLookup barFrameNum], [ring recordFrame],pixelsPerFrame);
    for (SInt32 i = drawStartFrame; i < [ring recordFrame]; i++){
        float val = [ring startPtrLeft][i];
        CGFloat x = (i - drawStartFrame) * pixelsPerFrame;
//        [line moveToPoint:NSMakePoint(x,h/2 - fabs(val)*h/2)];
//        [line lineToPoint:NSMakePoint(x,h/2 + fabs(val)*h/2)];
    }
    NSLog(@"drawRect");
    [line stroke];
}

@end
