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
    UInt32 pixelsPerRegion = (UInt8)(self.bounds.size.width / 8);
    UInt32 beatRegionDivide8 = location.x / pixelsPerRegion;
    
    [_delegate jugglingTouchViewMouseDown:beatRegionDivide8];
}

-(void)mouseUp:(NSEvent *)event{
    [_delegate touchViewMouseUp];
}


@end
