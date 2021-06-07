//
//  BitCrasherController.m
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "BitCrasherController.h"

@interface BitCrasherController ()

@end

@implementation BitCrasherController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)setBitCrasher:(BitCrasher *)crasher{
    _crasher = crasher;
}

- (IBAction)activeChanged:(id)sender {
    [_crasher setActive:(_chkActive.state == NSControlStateValueOn)];
}

@end
