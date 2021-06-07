//
//  RingView.m
//  MyPlaythrough
//
//  Created by kyab on 2017/05/25.
//  Copyright © 2017年 kyab. All rights reserved.
//

#import "RingView.h"

@implementation RingView

- (void)awakeFromNib{
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}


-(void)onTimer:(NSTimer *)t{
    if (!_ringBuffer){
        return;
    }
    
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [NSColor.blackColor set];
    NSRectFill(dirtyRect);
    
    if (!_ringBuffer) return;
    
    CGFloat recordRate = (CGFloat)[_ringBuffer recordFrame] / [_ringBuffer frames];
    CGFloat playRate = (CGFloat)[_ringBuffer playFrame] / [_ringBuffer frames];
    CGFloat recordPoint = self.bounds.size.width * recordRate;
    CGFloat playPoint = self.bounds.size.width * playRate;
    
    NSBezierPath *recordLine = [NSBezierPath bezierPath];
    NSBezierPath *playLine = [NSBezierPath bezierPath];
    
    [recordLine moveToPoint:NSMakePoint(recordPoint,0)];
    [recordLine lineToPoint:NSMakePoint(recordPoint,self.bounds.size.height)];
    [recordLine setLineWidth:3.0];
    
    [playLine moveToPoint:NSMakePoint(playPoint,0)];
    [playLine lineToPoint:NSMakePoint(playPoint,self.bounds.size.height)];
    [playLine setLineWidth:3.0];
 
    [NSColor.orangeColor set];
    [playLine stroke];
    
    [NSColor.lightGrayColor set];
    [recordLine stroke];
 
    
}

-(void)setRingBuffer:(RingBuffer *)ring{
    _ringBuffer = ring;
}

@end
