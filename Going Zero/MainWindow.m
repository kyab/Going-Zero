//
//  MainWindow.m
//  Going Zero
//
//  Created by koji on 2024/04/04.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "MainWindow.h"

@implementation MainWindow

- (void)awakeFromNib{
    NSLog(@"MainWindow awakeFromNib");
}

-(void)keyDown:(NSEvent *)event{
    NSLog(@"MainWindow keyDown code = %d, %@", event.keyCode, event.characters);
    [super keyDown:event];
}

@end
