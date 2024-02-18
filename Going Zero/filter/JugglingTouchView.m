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
    // Drawing code here.
}

-(void)setDelegate:(id<JugglingTouchViewDelegate>)delegate{
    _delegate = delegate;
}

- (void)mouseDown:(NSEvent *)event{
//    //get location on this view
//    NSPoint l = [event locationInWindow];
//    NSPoint location = [self convertPoint:l fromView:nil];
//    double ratio = location.x / self.frame.size.width;
//    NSLog(@"ratio = %f", ratio);
//    
//    [_delegate touchViewMouseDown: ratio];
    
    
     // mod 8
}

-(void)mouseUp:(NSEvent *)event{
    NSLog(@"mouse up");
    
    [_delegate touchViewMouseUp];

}


@end
