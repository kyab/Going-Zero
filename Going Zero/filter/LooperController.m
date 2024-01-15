//
//  LooperController.m
//  Going Zero
//
//  Created by koji on 2024/01/14.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "LooperController.h"

@interface LooperController ()

@end

@implementation LooperController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)setLooper:(Looper *)looper{
    _looper = looper;
}

- (IBAction)looperMarkStart:(id)sender {
    [_looper markStart];
}

- (IBAction)looperMarkEnd:(id)sender {
    [_looper markEnd];
}

- (IBAction)looperExit:(id)sender {
    [_looper exit];
}

- (IBAction)looperDoHalf:(id)sender {
    [_looper doHalf];
}

@end
