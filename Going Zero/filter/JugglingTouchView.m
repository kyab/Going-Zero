//
//  JugglingTouchView.m
//  Going Zero
//
//  Created by koji on 2024/02/19.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "JugglingTouchView.h"

@implementation JugglingTouchView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [NSColor.blackColor set];
    NSRectFill(self.bounds);
}

-(void)setDelegate:(id<JugglingTouchViewDelegate>)delegate{
    _delegate = delegate;
}

- (void)mouseDown:(NSEvent *)event{
    //get location on this view
    NSPoint l = [event locationInWindow];
    NSPoint location = [self convertPoint:l fromView:nil];
    CGFloat pixelsPerRegion = self.bounds.size.width / 16.0;
    UInt32 beatRegionDivide16 = (UInt32)(location.x / pixelsPerRegion);
        
    [_delegate jugglingTouchViewMouseDown:beatRegionDivide16];
}

-(void)mouseUp:(NSEvent *)event{
    [_delegate touchViewMouseUp];
}


@end
