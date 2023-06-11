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
    
    [_btnLookup sendActionOn:NSEventMaskLeftMouseDown | NSEventMaskLeftMouseUp];
    [_touchView setDelegate:self];
    
    _btnLookupPressing = NO;
}

- (void)setLookUp:(Lookup *)lookup{
    _lookup = lookup;
    [_touchView setLookup:_lookup];
}

- (IBAction)startMarkClicked:(id)sender {
    [_lookup startMark];
}

- (IBAction)loopingClicked:(id)sender {
    [_lookup startLooping];
}
- (IBAction)lookUpClicked:(id)sender {
    
    
    if(_btnLookupPressing){
        [_btnLookup setState:NSControlStateValueOff];
        _btnLookupPressing = NO;
        [_lookup stopLookupping];
    }else{
        [_btnLookup setState:NSControlStateValueOn];
        _btnLookupPressing = YES;
        [_lookup startLookupping:0.0];
    }
}

-(void)touchViewMouseDown:(double)xRatio{
    [_lookup startLookupping:xRatio];
}

-(void)touchViewMouseUp{
    [_lookup stopLookupping];
}

@end
