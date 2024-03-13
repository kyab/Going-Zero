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
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
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
    
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
        
    UInt32 barFrameStart = [_beatLookup barFrameStart];
    RingBuffer *ring = [_beatLookup ring];
    CGFloat framesPer01Pixel = (1 * [_beatLookup barFrameNum]) / w / 10.0;
    
    if ([_beatLookup state] == BL_STATE_STORING || [_beatLookup state] == BL_STATE_INLIVE){
        NSBezierPath *line = [NSBezierPath bezierPath];
        [line setLineWidth:0.1];
        [[NSColor orangeColor] set];
        
        SInt32 drawStartFrame = barFrameStart;
        SInt32 recordFrame = (SInt32)[ring recordFrame];
        if (barFrameStart > recordFrame){
            drawStartFrame -= [ring frames];
        }
        
        SInt32 f = drawStartFrame;
        for (int i = 0; i < w*10; i++){
            float max = 0.0f;
            SInt32 fs = f;
            Boolean shouldBreak = false;
            while((f - fs) < (SInt32)framesPer01Pixel){
                float val = [ring startPtrLeft][f++];
                if (fabs(val) > max){
                    max = fabs(val);
                }
                if (f >= recordFrame ){
                    shouldBreak = true;
                    break;
                }
            }
            max *= 0.95f;
            [line moveToPoint:NSMakePoint(i/10.0, h/2 - max*h/2)];
            [line lineToPoint:NSMakePoint(i/10.0, h/2 + max*h/2)];
            if (shouldBreak){
                break;
            }
        }
        [line stroke];
    }else if([_beatLookup state] == BL_STATE_BEATJUGGLING){
        BeatJugglingContext beatJugglingContext = [_beatLookup beatJugglingContext];
        int i = 0;
        {
            //pre
            NSBezierPath *line = [NSBezierPath bezierPath];
            [line setLineWidth:0.1];
            [[NSColor orangeColor] set];
            
            SInt32 drawStartFrame = barFrameStart;
            
            SInt32 f = drawStartFrame;
            for ( ; i < w*10; i++){
                float max = 0.0f;
                SInt32 fs = f;
                Boolean shouldBreak = false;
                SInt32 to = (SInt32)beatJugglingContext.startFrame + [_beatLookup barFrameNum];
                if (f > to){
                    to += RING_SIZE_SAMPLE;
                }
                
                while((f - fs) < (SInt32)framesPer01Pixel){
                    float val = [ring startPtrLeft][f++];
                    if (fabs(val) > max){
                        max = fabs(val);
                    }
                    if (f >= to ){
                        shouldBreak = true;
                        break;
                    }
                }
                max *= 0.95f;
                [line moveToPoint:NSMakePoint(i/10.0, h/2 - max*h/2)];
                [line lineToPoint:NSMakePoint(i/10.0, h/2 + max*h/2)];
                if (shouldBreak){
                    break;
                }
            }
            [line stroke];
        }
        
        {
            //during
            // startFrame -> (currentFrameInRegion + startFrame)
            NSBezierPath *line = [NSBezierPath bezierPath];
            [line setLineWidth:0.1];
            [[NSColor greenColor] set];
            
            SInt32 drawStartFrame = (SInt32)beatJugglingContext.startFrame;
            
            SInt32 f = drawStartFrame;
            for (; i < w*10; i++){
                float max = 0.0f;
                SInt32 fs = f;
                Boolean shouldBreak = false;
                SInt32 to = (SInt32)beatJugglingContext.startFrame + (SInt32)beatJugglingContext.currentFrameInRegion;
                
                while((f - fs) < (SInt32)framesPer01Pixel){
                    float val = [ring startPtrLeft][f++];
                    if (fabs(val) > max){
                        max = fabs(val);
                    }
                    if (f >= to ){
                        shouldBreak = true;
                        break;
                    }
                }
                max *= 0.95f;
                [line moveToPoint:NSMakePoint(i/10.0, h/2 - max*h/2)];
                [line lineToPoint:NSMakePoint(i/10.0, h/2 + max*h/2)];
                if (shouldBreak){
                    break;
                }
            }
            [line stroke];
        }
        
        {
            //post
        }

    }
}

@end
