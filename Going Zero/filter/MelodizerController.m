//
//  MelodizerController.m
//  Going Zero
//
//  Created by koji on 2026/08/24.
//  Copyright © 2026 kyab. All rights reserved.
//

#import "MelodizerController.h"

@interface MelodizerController ()

@end

@implementation MelodizerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)setMelodizer:(Melodizer *)melodizer{
    _melodizer = melodizer;
}

//-(void)replayZero{
//    [_melodizer replayZero];
//}
//
//-(void)replayPlusOne{
//    [_melodizer replayPlusOne];
//}
//
//-(void)replayMinusOne{
//    [_melodizer replayMinusOne];
//}
//
//-(void)stopReplay{
//    [_melodizer stopReplay];
//}

-(void)setTranspose:(float)pitchShift{
    NSLog(@"Melodizer(Controller): setTranspose:%f", pitchShift);
    [_melodizer setTranspose:pitchShift];
}

-(void)stopTranspose{
    [_melodizer stopTranspose];
}

- (IBAction)transposeNoteCClicked:(id)sender{
    [self setTranspose:0.0f];
}

- (IBAction)transposeNoteDClicked:(id)sender{
    [self setTranspose:2.0f];
}

- (IBAction)transposeNoteBClicked:(id)sender{
    [self setTranspose:-1.0f];
}

- (IBAction)enableChanged:(id)sender {
    [_melodizer setActive:(_chkActive.state == NSControlStateValueOn)];
}




@end
