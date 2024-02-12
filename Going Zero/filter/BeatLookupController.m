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
    // Do view setup here.
}

-(void)setBeatLookup:(BeatLookup *)beatLookup{
    _beatLookup = beatLookup;
    [_beatLookupWaveView setBeatLookup:_beatLookup];
}

- (IBAction)setBarStart:(id)sender {
    [_beatLookup setBarStart];
}


@end
