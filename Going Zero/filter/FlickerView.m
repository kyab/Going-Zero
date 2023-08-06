//
//  FlickerView.m
//  Going Zero
//
//  Created by koji on 2023/08/06.
//  Copyright © 2023 kyab. All rights reserved.
//

#import "FlickerView.h"

@implementation FlickerView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [[NSColor blueColor] set];
    NSRectFill(dirtyRect);
    // Drawing code here.
}

@end
