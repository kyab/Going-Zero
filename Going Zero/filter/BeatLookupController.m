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
}

-(void)setBeatLookup:(BeatLookup *)beatLookup{
    _beatLookup = beatLookup;
    [_beatLookupWaveView setBeatLookup:_beatLookup];
}

- (IBAction)setBarStart:(id)sender {
    [_beatLookup setBarStart];
}

-(void)jugglingTouchViewMouseDown:(UInt32)beatRegionDivide16{
    [_beatLookup startBeatJuggling:beatRegionDivide16];
}

-(void)touchViewMouseUp{
    [_beatLookup stopBeatJuggling];
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
        [_beatLookup setPitch:0.0];
        return;
    }
    
    [_beatLookup setPitch:[_pitchSlider floatValue]];
}


@end
