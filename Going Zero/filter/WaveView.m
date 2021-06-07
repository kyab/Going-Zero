//
//  WaveView.m
//  Going Zero
//
//  Created by kyab on 2021/06/03.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "WaveView.h"

@implementation WaveView

- (void)awakeFromNib{
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    
}

- (void)setRingBuffer:(RingBuffer *)ring{
    _ring = ring;
}

-(void)onTimer:(NSTimer *)timer{
//    NSLog(@"WaveView onTimer");
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    if (!_ring) return;
    
    
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    
    // Drawing code here.
    [[NSColor blackColor] set];
    NSRectFill(dirtyRect);
    
    
    //view latest
    CGFloat w = self.frame.size.width;
    CGFloat h = self.frame.size.height;
    
    [[NSColor orangeColor] set];
    
    NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(0,h/2)];
    [line lineToPoint:NSMakePoint(w,h/2)];
    [line stroke];
    
    float *bufL = [_ring writePtrLeft] - 4410;
    float *bufR = [_ring writePtrRight] - 4410;
    
    
    for(int i = 0; i < w; i++){
        float max = 0;
        for (int j = (int)i*round(4410/w); j < (int)i*round(4410/w) + (int)round(4410/w); j++){
            
            float val = fabs(bufL[j]);
            if (val < fabs(bufR[j])){
                val = fabs(bufR[j]);
            }
            
            if (val > max){
                max = val;
            }
        }
        NSBezierPath *line = [NSBezierPath bezierPath];
        [line moveToPoint:NSMakePoint(i, h/2 - h/2*max)];
        [line lineToPoint:NSMakePoint(i, h/2 + h/2*max)];
        [line setLineWidth:1.0];
        [line stroke];
    }
    
    
}

@end
