//
//  VocalRefrainController.m
//  Going Zero
//
//  Created by kyab on 2021/06/12.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "VocalRefrainController.h"


@interface VocalRefrainController ()

@end

@implementation VocalRefrainController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)setVocalRefrain:(VocalRefrain *)vocalRefrain{
    _vocalRefrain = vocalRefrain;
}

- (IBAction)markClicked:(id)sender {
    switch([_vocalRefrain state]){
        case VOCALREFRAIN_STATE_NONE:
            [_vocalRefrain startMark];
            [_btnMark setTitle:@"Refrain"];
            break;
        case VOCALREFRAIN_STATE_MARKING:
            [_vocalRefrain startRefrain];
            break;
        case VOCALREFRAIN_STATE_REFRAINING:
            break;
    }
}

- (IBAction)exitClicked:(id)sender {
//    if ([_refrain state] == REFRAIN_STATE_REFRAINING){
        [_vocalRefrain exit];
        [_btnMark setTitle:@"Mark"];
//    }
}

- (IBAction)panChanged:(id)sender {
    [_vocalRefrain setPan:_sliderPan.floatValue];
}

@end
