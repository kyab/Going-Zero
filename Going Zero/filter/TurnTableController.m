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
    _wetVolume = 1.0;
    _dryVolume = 0.0;
    _speedRate = 1.0;
}

-(void)setRingBuffer:(RingBuffer *)ring{
    _ring = ring;
    [_turnTableView setRingBuffer:_ring];
    [_turnTableView start];
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

- (IBAction)wetVolumeChanged:(id)sender {
    _wetVolume = [_sliderWetVolume floatValue];
}

- (IBAction)dryVolumeChanged:(id)sender {
    _dryVolume = [_sliderDryVolume floatValue];
}

-(float)wetVolume{
    return _wetVolume;
}

-(float)dryVolume{
    return _dryVolume;
}

-(double)speedRate{
    return _speedRate;
}


@end
