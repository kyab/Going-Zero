//
//  RefrainController.m
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "RefrainController.h"

@interface RefrainController ()

@end

@implementation RefrainController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)setRefrain:(Refrain *)refrain{
    _refrain = refrain;
}

- (IBAction)markClicked:(id)sender {
    switch([_refrain state]){
        case REFRAIN_STATE_NONE:
            [_refrain startMark];
            [_btnMark setTitle:@"Refrain"];
            break;
        case REFRAIN_STATE_MARKING:
            [_refrain startRefrain];
            break;
        case REFRAIN_STATE_REFRAINING:
            break;
    }
}

- (IBAction)exitClicked:(id)sender {
//    if ([_refrain state] == REFRAIN_STATE_REFRAINING){
        [_refrain exit];
        [_btnMark setTitle:@"Mark"];
//    }
}
- (IBAction)panChanged:(id)sender {
    [_refrain setPan:[_sliderPan floatValue]];
}


@end
