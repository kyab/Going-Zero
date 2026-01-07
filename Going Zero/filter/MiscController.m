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

- (void)dealloc {
    // Remove KVO observer
    if (_freezer) {
        [_freezer removeObserver:self forKeyPath:@"active"];
    }
}

- (void)setBender:(Bender *)bender{
    _bender = bender;
}

- (void)setTrillReverse:(TrillReverse *)trillReverse{
    _trillReverse = trillReverse;
}

- (void)setFreezer:(Freezer *)freezer{
    // Remove old observer if exists
    if (_freezer) {
        [_freezer removeObserver:self forKeyPath:@"active"];
    }
    
    _freezer = freezer;
    
    // Add KVO observer for active property
    if (_freezer) {
        [_freezer addObserver:self forKeyPath:@"active" options:NSKeyValueObservingOptionNew context:NULL];
        // Initial UI sync
        [self syncUIWithModel];
    }
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
    // Update model state (UI will be updated via KVO)
    [_freezer setActive:(_chkFreeze.state == NSControlStateValueOn)];
}

- (IBAction)freezeGrainsizeChanged:(id)sender {
    [_freezer setGrainSize:[_sliderGrainSize intValue]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"active"] && object == _freezer) {
        // Update UI on main thread when model state changes
        dispatch_async(dispatch_get_main_queue(), ^{
            [self syncUIWithModel];
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)syncUIWithModel {
    // Sync UI checkbox with model state
    BOOL active = [_freezer active];
    [_chkFreeze setState:active ? NSControlStateValueOn : NSControlStateValueOff];
}

@end
