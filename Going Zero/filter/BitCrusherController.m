//
//  BitCrusherController.m
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "BitCrusherController.h"

@interface BitCrusherController ()

@end

@implementation BitCrusherController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)setBitCrusher:(BitCrusher *)crusher{
    _crusher = crusher;
}

- (IBAction)activeChanged:(id)sender {
    [_crusher setActive:(_chkActive.state == NSControlStateValueOn)];
}

@end
