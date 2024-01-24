//
//  TurnTableController.m
//  Going Zero
//
//  Created by yoshioka on 2024/01/24.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "TurnTableController.h"

@interface TurnTableController ()

@end

@implementation TurnTableController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_turnTableView setDelegate:self];
    _speedRate = 1.0;
}

-(void)setRingBuffer:(RingBuffer *)ring{
    _ring = ring;
}

-(void)setMiniFaderIn:(MiniFaderIn *)faderIn{
    _faderIn = faderIn;
}

-(void)turnTableSpeedRateChanged{
    _speedRate = [_turnTableView speedRate];
    if (_speedRate == 1.0){
        [_ring follow];
        [_faderIn startFadeIn];
        return;
    }
}

@end
