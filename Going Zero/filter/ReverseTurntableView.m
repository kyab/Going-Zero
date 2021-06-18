//
//  ReverseTurntableView.m
//  Going Zero
//
//  Created by kyab on 2021/06/13.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "ReverseTurntableView.h"

@implementation ReverseTurntableView

-(void)awakeFromNib{
    _currentRad = 28 * (M_PI / 180);
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];

    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    
    _reverse = NO;
    
}

-(void)startReverse{
    _reverse = YES;
}
-(void)stopReverse{
    _currentRad = 28 * (M_PI / 180);
    _reverse = NO;
}

-(void)onTimer:(NSTimer *)timer{
    if (!_reverse){
        _currentRad += -33.3/60 *2 * M_PI * 0.01;
    }else{
        _currentRad -= -33.3/60 *2 * M_PI * 0.01;
    }
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    CGFloat r1 = self.bounds.size.height/2;
    CGFloat r2 = self.bounds.size.width/2;
    CGFloat r = 0;
    if (r1 > r2){
        r = r2;
    }else{
        r = r1;
    }
    
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    
    NSBezierPath *circlePath = [NSBezierPath
                                bezierPathWithOvalInRect:NSMakeRect((w - 2*r)/2, (h-2*r)/2, 2*r, 2*r)];
    [[NSColor grayColor] set];
    [circlePath fill];
    
    CGFloat centerX = w/2;
    CGFloat centerY = h/2;
    
    NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(centerX, centerY)];
    [line lineToPoint:NSMakePoint(centerX + r * cos(_currentRad),
                                  centerY + r * sin(_currentRad)) ];
    [[NSColor orangeColor] set];
    [line setLineWidth:2.0];
    [line stroke];
    
}

@end
