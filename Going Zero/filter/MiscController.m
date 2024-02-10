//
//  MiscController.m
//  Going Zero
//
//  Created by yoshioka on 2024/01/17.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "MiscController.h"
#import "Bender.h"
#import "TrillReverse.h"
#import "Freezer.h"

@interface MiscController ()

@end

@implementation MiscController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)setBender:(Bender *)bender{
    _bender = bender;
}

- (void)setTrillReverse:(TrillReverse *)trillReverse{
    _trillReverse = trillReverse;
}

- (void)setFreezer:(Freezer *)freezer{
    _freezer = freezer;
}

- (IBAction)_benderRateChanged:(id)sender {
    
    NSLog(@"new bounce");
    
    [_bender setRate:[_sliderBenderRate floatValue]];
    if([[NSApplication sharedApplication] currentEvent].type == NSEventTypeLeftMouseUp){
        NSLog(@"bounce!");
        //[_sliderBenderRate setFloatValue:1.0];
        if(![_bender bounce]){
            [_bender resetRate];
            [_sliderBenderRate setFloatValue:1.0];
        }else{
            [self startBounce];
        }
    }
}

- (IBAction)_benderBounceChanged:(id)sender {
    [_bender setBounce:(_chkBenderBounce.state == NSControlStateValueOn)];
}

-(void)startBounce{
    _benderBounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(onBounceTimer:) userInfo:nil repeats:YES];
    
}

-(void)onBounceTimer:(NSTimer *)timer{
    
    if ([_bender isCatchingUp]){
        [_benderBounceTimer invalidate];
        [_sliderBenderRate setFloatValue:1.0];
        [_bender resetRate];
        return;
    }

    float rate = _sliderBenderRate.floatValue;
    rate += 0.1;
    if (rate >= 1.5){
        rate = 1.5;
    }
    [_sliderBenderRate setFloatValue:rate];
    [_bender setRate:rate];
    
}

- (IBAction)_trillReverseChanged:(id)sender {
    [_trillReverse setActive:([_chkTrillReverse state] == NSControlStateValueOn)];
}

- (IBAction)freezeChanged:(id)sender {
    [_freezer setActive:(_chkFreeze.state == NSControlStateValueOn)];
}

- (IBAction)freezeGrainsizeChanged:(id)sender {
    [_freezer setGrainSize:[_sliderGrainSize intValue]];
}

@end
