//
//  MainViewController.m
//  Going Zero
//
//  Created by kyab on 2021/11/11.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view.window makeFirstResponder:self];
    
    _upPressed = NO;
    _downPressed = NO;
}

-(Boolean)isUpKeyPressed{
    return _upPressed;
}

-(Boolean)isDownKeyPressed{
    return _downPressed;
}

-(void)keyDown:(NSEvent *)event{
    switch (event.keyCode){
        case 7: //x
            _upPressed = YES;
            break;
        case 6: //z
            _downPressed = YES;
            break;
        default:
            [super keyDown:event];
            break;
    }
}

-(void)keyUp:(NSEvent *)event{
    switch (event.keyCode){
        case 7: //x
            _upPressed = NO;
            break;
        case 6: //z
            _downPressed = NO;
            break;
        default:
            [super keyUp:event];
            break;
    }
}

@end
