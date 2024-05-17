//
//  AutoLooperController.m
//  Going Zero
//
//  Created by yoshioka on 2024/05/01.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "AutoLooperController.h"

@interface AutoLooperController ()

@end

@implementation AutoLooperController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)setAutoLooper:(AutoLooper *)autoLooper{
    _autoLooper = autoLooper;
    [self refreshLoopLengthLabel];
}

-(void)refreshLoopLengthLabel{
    UInt32 divider = [_autoLooper baseDivider];
    
    if (divider == 1){
        [_lblLoopLength setStringValue:@"1"];
    }else{
        [_lblLoopLength setStringValue:[NSString stringWithFormat:@"1/%u", divider]];
    }
}

@end
