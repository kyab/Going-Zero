//
//  TouchView.m
//  Going Zero
//
//  Created by koji on 2023/06/04.
//  Copyright © 2023 kyab. All rights reserved.
//

#import "TouchView.h"

@implementation TouchView

- (void)awakeFromNib{
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

-(void)onTimer:(NSTimer *)timer{
    [self setNeedsDisplay:YES];
}


-(void)setDelegate:(id<TouchViewDelegate>)delegate{
    _delegate = delegate;
}

-(void)setLookup:(Lookup *)lookup{
    _lookup = lookup;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    CGFloat h = self.frame.size.height;
    CGFloat w = self.frame.size.width;
    
    NSRect upperRect = NSMakeRect(0, h/2+5, w, h/2-5);
    [NSColor.blackColor set];
    NSRectFill(upperRect);
    
    NSRect lowerRect = NSMakeRect(0, 0, w, h/2-5);
    [NSColor.purpleColor set];
    NSRectFill(lowerRect);
    
    if (!_lookup) return;
    UInt32 barDuration = [_lookup barDuration];
    if (barDuration > 0 ){
        double xRatio = [_lookup playFrameInBar] / (double)barDuration;
        double x = w * xRatio;
        NSBezierPath *line = [NSBezierPath bezierPath];
        [line moveToPoint:NSMakePoint(x, h/2+5)];
        [line lineToPoint:NSMakePoint(x, h)];
        [[NSColor yellowColor] set];
        [line stroke];
        
        xRatio = [_lookup recordFrameInBar] / (double)barDuration;
        x = w * xRatio;
        line = [NSBezierPath bezierPath];
        [line moveToPoint:NSMakePoint(x, 0)];
        [line lineToPoint:NSMakePoint(x, h/2-5)];
        [[NSColor redColor] set];
        [line stroke];
    }
        
}


- (void)mouseDown:(NSEvent *)event{
    //get location on this view
    NSPoint l = [event locationInWindow];
    NSPoint location = [self convertPoint:l fromView:nil];
    double ratio = location.x / self.frame.size.width;
    NSLog(@"ratio = %f", ratio);
    
    [_delegate touchViewMouseDown: ratio];
}

-(void)mouseUp:(NSEvent *)event{
    NSLog(@"mouse up");
    
    [_delegate touchViewMouseUp];

}

@end
