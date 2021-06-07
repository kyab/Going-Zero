//
//  MyButton.m
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "MyButton.h"

@implementation MyButton

- (void)awakeFromNib{
    [self sendActionOn:NSEventMaskLeftMouseDown];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}



@end
