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

- (void)setViewer:(Viewer *)viewer{
    _viewer = viewer;
}

-(void)onTimer:(NSTimer *)timer{
    [self setNeedsDisplay:YES];
}

-(void)viewDidMoveToSuperview {
    [super viewDidMoveToSuperview];
    
    self.wantsLayer = YES;
    self.layer.backgroundColor = [NSColor blackColor].CGColor;
}

-(void)viewDidMoveToWindow{
    [super viewDidMoveToWindow];
    
    self.wantsLayer = YES;
    self.layer.backgroundColor = [NSColor blackColor].CGColor;
}

- (void)drawRect:(NSRect)dirtyRect {

    [super drawRect:dirtyRect];

    [[NSGraphicsContext currentContext] setShouldAntialias:NO];

    if (!_viewer) {
        return;
    }
    if (![_viewer isEnabled]) return;
    
    
    //view latest
    CGFloat w = self.frame.size.width;
    CGFloat h = self.frame.size.height;
    
    [[NSColor orangeColor] set];
    
    NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(0,h/2)];
    [line lineToPoint:NSMakePoint(w,h/2)];
    [line stroke];
    
    RingBuffer *ring = [_viewer ring];
    
    float *bufL = [ring writePtrLeft] - 44100 - (ptrdiff_t)(ceil(44100/w));
    float *bufR = [ring writePtrRight] - 44100 - (ptrdiff_t)(ceil(44100/w));
    
    
    for(int i = 0; i < w; i++){
        float max = 0;
        for (int j = (int)i*floor(44100/w); j < (int)i*floor(44100/w) + (int)floor(44100/w); j++){
            
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
