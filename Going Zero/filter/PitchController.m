//
//  PitchController.m
//  Going Zero
//
//  Created by koji on 2025/06/18.
//  Copyright © 2025 kyab. All rights reserved.
//

#import "PitchController.h"

@interface PitchController ()

@end

@implementation PitchController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_textFieldPitchValue setStringValue:@"0.0"];
}

- (void)setPitch:(Pitch *)pitch {
    _pitch = pitch;
}

- (IBAction)pitchChanged:(id)sender {
    NSSliderCell *slider = (NSSliderCell *)sender;
    float pitchShiftValue = slider.floatValue - 3.0;
    NSLog(@"Pitch shift value: %f", pitchShiftValue);
    
    [_pitch setPitchShift:pitchShiftValue];
    
    [_textFieldPitchValue setStringValue:[NSString stringWithFormat:@"%.1f", pitchShiftValue]];
}


@end
