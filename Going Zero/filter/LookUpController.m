//
//  LookUpController.m
//  Going Zero
//
//  Created by koji on 2023/05/27.
//  Copyright © 2023 kyab. All rights reserved.
//

#import "LookUpController.h"

@interface LookUpController ()

@end

@implementation LookUpController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)setLookUp:(LookUp *)lookUp{
    _lookUp = lookUp;
}

- (IBAction)startMarkClicked:(id)sender {
    [_lookUp startMark];
}

- (IBAction)loopingClicked:(id)sender {
    [_lookUp startLooping];
}

@end
