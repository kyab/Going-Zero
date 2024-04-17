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
    
    if ([_beatLookup state] == BL_STATE_STORING || [_beatLookup state] == BL_STATE_INLIVE || [_beatLookup state] == BL_STATE_PITCHSHIFTING){
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
            
            SInt32 startFrame = barFrameStart;
            SInt32 endFrame = (SInt32)beatJugglingContext.startFrame + [_beatLookup barFrameNum];
            if (endFrame < startFrame){
                endFrame += RING_SIZE_SAMPLE;
            }
            
            SInt32 f = startFrame;
            for ( ; i < w*10; i++){
                float max = 0.0f;
                SInt32 fs = f;
                Boolean shouldBreak = false;
                
                while((f - fs) < (SInt32)framesPer01Pixel){
                    float val = [ring startPtrLeft][f++];
                    if (fabs(val) > max){
                        max = fabs(val);
                    }
                    if (f >= endFrame ){
                        shouldBreak = true;
                        break;
                    }
                }
                max *= 0.95f;
                if (f < [ring recordFrame]){
                    [line moveToPoint:NSMakePoint(i/10.0, h/2 - max*h/2)];
                    [line lineToPoint:NSMakePoint(i/10.0, h/2 + max*h/2)];
                }
                if (shouldBreak){
                    break;
                }
            }
            [line stroke];
        }
        
        {
            //during
            NSBezierPath *line = [NSBezierPath bezierPath];
            [line setLineWidth:0.1];
            [[NSColor cyanColor] set];
            
            SInt32 startFrame = (SInt32)beatJugglingContext.startFrame;
            SInt32 endFrame = (SInt32)beatJugglingContext.startFrame + (SInt32)beatJugglingContext.currentFrameInRegion;
            
            SInt32 f = startFrame;
            for (; i < w*10; i++){
                float max = 0.0f;
                SInt32 fs = f;
                Boolean shouldBreak = false;
                
                while((f - fs) < (SInt32)framesPer01Pixel){
                    float val = [ring startPtrLeft][f++];
                    if (fabs(val) > max){
                        max = fabs(val);
                    }
                    if (f >= endFrame ){
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
            NSBezierPath *line = [NSBezierPath bezierPath];
            [line setLineWidth:0.1];
            [[NSColor orangeColor] set];
            
            SInt32 startFrame = (SInt32)beatJugglingContext.startFrame + (SInt32)beatJugglingContext.currentFrameInRegion + [_beatLookup barFrameNum];
            if (startFrame > RING_SIZE_SAMPLE){
                startFrame -= RING_SIZE_SAMPLE;
            }
            SInt32 endFrame = [ring recordFrame];
            
            SInt32 f = startFrame;
            for ( ; i < w*10; i++){
                float max = 0.0f;
                SInt32 fs = f;
                Boolean shouldBreak = false;
                
                while((f - fs) < (SInt32)framesPer01Pixel){
                    float val = [ring startPtrLeft][f++];
                    if (fabs(val) > max){
                        max = fabs(val);
                    }
                    if (f >= endFrame ){
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

    }
}

@end
