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
    _isLooping = NO;
}

-(void)setAutoLooper:(AutoLooper *)autoLooper{
    _autoLooper = autoLooper;
}

-(void)refreshLoopLengthLabel{
    UInt32 divider = [_autoLooper divider];
    
    if (divider == 1){
        [_lblLoopLength setStringValue:@"1"];
    }else{
        [_lblLoopLength setStringValue:[NSString stringWithFormat:@"1/%u", divider]];
    }
}

- (IBAction)oneBarClicked:(id)sender {
    if (!_isLooping){
        [_autoLooper startQuantizedLoop];
        _isLooping = YES;
    }else{
        [_autoLooper exitLoop];
        _isLooping = NO;
    }
}


@end
