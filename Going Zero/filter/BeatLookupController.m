//
//  BeatLookupController.m
//  Going Zero
//
//  Created by yoshioka on 2024/01/31.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "BeatLookupController.h"

@interface BeatLookupController ()

@end

@implementation BeatLookupController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_jugglingTouchView setDelegate:self];
    _isTimeShifting = NO;
    _isPitchShifting = NO;
}

-(void)setBeatLookup:(BeatLookup *)beatLookup{
    _beatLookup = beatLookup;
    [_beatLookupWaveView setBeatLookup:_beatLookup];
}

- (IBAction)setBarStart:(id)sender {
    [_beatLookup setBarStart];
}

-(void)jugglingTouchViewMouseDown:(UInt32)beatRegionDivide16{
    [_beatLookup beginBeatJuggling:beatRegionDivide16];
}

-(void)jugglingTouchViewMouseUp{
    [_beatLookup endBeatJuggling];
}

-(void)jugglingTouchViewTouchStart:(UInt32) beatRegionDivide16{
    [_beatLookup beginBeatJuggling:beatRegionDivide16];
}

-(void)jugglingTouchViewTouchMove:(UInt32) beatRegionDivide16{
    [_beatLookup changeBeatJuggling:beatRegionDivide16];
}

-(void)jugglingTouchViewTouchEnd{
    [_beatLookup endBeatJuggling];
}

- (IBAction)finelyChanged:(id)sender {
    if ([_chkFinely state] == NSControlStateValueOn){
        [_beatLookup setFineGrained:true];
    }else{
        [_beatLookup setFineGrained:false];
    }
}

- (IBAction)pitchChanged:(id)sender {
    if ([[NSApplication sharedApplication] currentEvent].type == NSEventTypeLeftMouseUp){
        [_sliderPitch setFloatValue:0.0];
        [_beatLookup setPitchShift:0.0];
        [_beatLookup endPitchShifting];
        _isPitchShifting = NO;
        return;
    }
    
    [_beatLookup setPitchShift:[_sliderPitch floatValue]];
    if (_isPitchShifting == NO){
        [_beatLookup beginPitchShifting];
        _isPitchShifting = YES;
    }
}

- (IBAction)timeChanged:(id)sender {
    if ([[NSApplication sharedApplication] currentEvent].type == NSEventTypeLeftMouseUp){
        [_sliderTime setFloatValue:0.0];
        [_beatLookup setTimeStretch:1.0];
        [_beatLookup endTimeStretching];
        _isTimeShifting = NO;
        return;
    }
    
    // scale delta from [-50 to 50] to [-50 to 75] so final stretch range will be [50% to 175%]
    float percentDelta = _sliderTime.floatValue;
    if (percentDelta > 0.0f){
        percentDelta *= 75.0/50.0;
    }
    [_beatLookup setTimeStretch:(100.0 + percentDelta)/100.0];
    if (_isTimeShifting == NO){
        [_beatLookup beginTimeStreching];
        _isTimeShifting = YES;
    }
}


@end
