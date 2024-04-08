//
//  PitchShifterController.m
//  Going Zero
//
//  Created by yoshioka on 2024/04/08.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "PitchShifterController.h"

@interface PitchShifterController ()

@end

@implementation PitchShifterController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)setPitchShifter:(PitchShifter *)pitchShifter{
    _pitchShifter = pitchShifter;
}
- (IBAction)sliderPitchShiftChanged:(id)sender {
    [_pitchShifter setPitchShift:[_sliderPitch floatValue]];
}

@end
