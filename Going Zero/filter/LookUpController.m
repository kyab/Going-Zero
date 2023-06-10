//
//  LookUpController.m
//  Going Zero
//
//  Created by koji on 2023/05/27.
//  Copyright © 2023 kyab. All rights reserved.
//

#import "LookUpController.h"

@interface LookUpController ()

@end

@implementation LookUpController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [_btnLookUp sendActionOn:NSEventMaskLeftMouseDown | NSEventMaskLeftMouseUp];
    [_touchView setDelegate:self];
    
    _btnLookUpPressing = NO;
}

- (void)setLookUp:(LookUp *)lookUp{
    _lookUp = lookUp;
}

- (IBAction)startMarkClicked:(id)sender {
    [_lookUp startMark];
}

- (IBAction)loopingClicked:(id)sender {
    [_lookUp startLooping];
}
- (IBAction)lookUpClicked:(id)sender {
    
    
    if(_btnLookUpPressing){
        [_btnLookUp setState:NSControlStateValueOff];
        _btnLookUpPressing = NO;
        [_lookUp stopLookUpping];
    }else{
        [_btnLookUp setState:NSControlStateValueOn];
        _btnLookUpPressing = YES;
        [_lookUp startLookUpping:0.0];
    }
}

-(void)touchViewMouseDown:(double)xRatio{
    [_lookUp startLookUpping:xRatio];
}

-(void)touchViewMouseUp{
    [_lookUp stopLookUpping];
}

@end
