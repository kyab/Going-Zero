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
    if (_keyDelegate){
        if ([_keyDelegate mainWindowKeyDown:event]){
            return;
        }
    }
    [super keyDown:event];
}

-(void)keyUp:(NSEvent *)event{
    NSLog(@"MainWindow keyUp code = %d, %@", event.keyCode, event.characters);
    if (_keyDelegate){
        if ([_keyDelegate mainWindowKeyUp:event]){
            return;
        }
    }
    [super keyUp:event];
}

-(void)setKeyDelegate:(id<MainWindowKeyDelegate>)keyDelegate{
    _keyDelegate = keyDelegate;
}
@end
