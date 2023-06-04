//
//  TouchView.m
//  Going Zero
//
//  Created by koji on 2023/06/04.
//  Copyright © 2023 kyab. All rights reserved.
//

#import "TouchView.h"

@implementation TouchView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [NSColor.blackColor set];
    NSRectFill(dirtyRect);

}


- (void)mouseDown:(NSEvent *)event{
    //get location on this view
    NSPoint l = [event locationInWindow];
    NSPoint location = [self convertPoint:l fromView:nil];
    NSLog(@"x = %f",location.x);
}

-(void)mouseUp:(NSEvent *)event{
    NSLog(@"mouse up");
}

@end
