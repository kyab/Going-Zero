//
//  RandomController.m
//  Going Zero
//
//  Created by kyab on 2021/12/06.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "RandomController.h"

@interface RandomController ()

@end

@implementation RandomController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)setRandom:(Random *)random{
    _random = random;
}

- (IBAction)bang:(id)sender {
    [_random start];
}


@end
