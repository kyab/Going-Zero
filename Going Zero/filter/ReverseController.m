//
//  ReverseController.m
//  Going Zero
//
//  Created by kyab on 2021/06/13.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "ReverseController.h"

@interface ReverseController ()

@end

@implementation ReverseController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [_btnReverse sendActionOn:NSEventMaskLeftMouseDown | NSEventMaskLeftMouseUp];
    
    _btnPressing = NO;
}

-(void)setReverse:(Reverse *)reverse{
    _reverse = reverse;
}

- (IBAction)reverseClicked:(id)sender {
    
    if(_btnPressing){
        [_btnReverse setState:NSControlStateValueOff];
        _btnPressing = NO;
        [_reverse stopReverse];
        [_ttView stopReverse];
    }else{
        [_btnReverse setState:NSControlStateValueOn];
        _btnPressing = YES;
        [_reverse startReverse];
        [_ttView startReverse];
    }
}


@end
