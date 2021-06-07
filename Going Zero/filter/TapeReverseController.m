//
//  TapeReverseController.m
//  Going Zero
//
//  Created by kyab on 2021/06/07.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "TapeReverseController.h"

@interface TapeReverseController ()

@end

@implementation TapeReverseController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)setTapeReverse:(TapeReverse *)tapeReverse{
    _tapeReverse = tapeReverse;
}

- (IBAction)rateChanged:(id)sender {
    
    if([[NSApplication sharedApplication] currentEvent].type == NSEventTypeLeftMouseUp){
        [_sliderRate setFloatValue:0];
        [_tapeReverse setRate:0.0];
        return;
    }

        
    float newRate = [_sliderRate floatValue];
    if (newRate == 0.0){
        ;
    }else{
        newRate -= 0.5;
    }
    [_tapeReverse setRate:newRate];
}

@end
