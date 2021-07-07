//
//  FlangerController.m
//  Going Zero
//
//  Created by kyab on 2021/07/04.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "FlangerController.h"

@interface FlangerController ()

@end

@implementation FlangerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


-(void)setFlanger:(Flanger *)flanger{
    _flanger = flanger;
}

- (IBAction)onOffChanged:(id)sender {
    if ([_chkOnOff state] == NSControlStateValueOn){
        [_flanger setBypass:NO];
    }else{
        [_flanger setBypass:YES];
    }
}

- (IBAction)depthChanged:(id)sender {
    [_flanger setDepth:_sliderDepth.floatValue];
}

- (IBAction)freqChanged:(id)sender {
    [_flanger setFreq:_sliderFreq.floatValue];
}

@end
