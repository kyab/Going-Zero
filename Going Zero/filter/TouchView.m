//
//  TouchView.m
//  Going Zero
//
//  Created by koji on 2023/06/04.
//  Copyright © 2023 kyab. All rights reserved.
//

#import "TouchView.h"

@implementation TouchView

-(void)setDelegate:(id<TouchViewDelegate>)delegate{
    _delegate = delegate;
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
