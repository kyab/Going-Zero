//
//  SimpleReverbController.m
//  Going Zero
//
//  Created by kyab on 2021/12/14.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "SimpleReverbController.h"

@interface SimpleReverbController ()

@end

@implementation SimpleReverbController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)setSimpleReverb:(SimpleReverb *)simpleReverb{
    _simpleReverb = simpleReverb;
}

- (IBAction)onOffChanged:(id)sender {
    if ([_chkOnOff state] == NSControlStateValueOn){
        [_simpleReverb setBypass:NO];
    }else{
        [_simpleReverb setBypass:YES];
    }
}


@end
