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
    [self refreshLoopLabel];
}

-(void)refreshLoopLabel{
    UInt32 divider = [_autoLooper baseDivider];
    
    if (divider == 1){
        [_lblLoop setStringValue:@"Manual 1"];
    }else{
        [_lblLoop setStringValue:[NSString stringWithFormat:@"Manual 1/%u", divider]];
    }
}

-(void)exitLoop{
    [_autoLooper exitLoop];
    [_lblLoop setBackgroundColor:NSColor.textBackgroundColor];
    [_lblLoop setDrawsBackground:NO];
    [_lblBounceLoop setStringValue:[NSString stringWithFormat:@"Bounce"]];
    [_lblBounceLoop setBackgroundColor:NSColor.textBackgroundColor];
    [_lblBounceLoop setDrawsBackground:NO];
    [_lblAutoLoop setBackgroundColor:NSColor.textBackgroundColor];
    [_lblAutoLoop setDrawsBackground:NO];
    [_lblAutoLoop setStringValue:[NSString stringWithFormat:@"Auto"]];
}

-(void)toggleQuantizedLoop{
    if ([_autoLooper isLooping]){
        [self exitLoop];
    }else{
        [self exitLoop];
        [_lblLoop setBackgroundColor:NSColor.systemCyanColor];
        [_lblLoop setDrawsBackground:YES];
        [_autoLooper startQuantizedNormalLoop];
    }
}

-(void)startQuantizedAutoLoop{
    [_lblAutoLoop setStringValue:[NSString stringWithFormat:@"Auto"]];
    [_autoLooper startQuantizedAutoLoop];
    [_lblAutoLoop setBackgroundColor:NSColor.systemCyanColor];
    [_lblAutoLoop setDrawsBackground:YES];
}

-(void)startQuantizedBounceLoop{
    [_lblBounceLoop setStringValue:[NSString stringWithFormat:@"Bounce 1"]];
    [_autoLooper startQuantizedBounceLoop];
    [_lblBounceLoop setBackgroundColor:NSColor.systemCyanColor];
    [_lblBounceLoop setDrawsBackground:YES];
}

-(void)startQuantizedBounceLoopHalf{
    [_lblBounceLoop setStringValue:[NSString stringWithFormat:@"Bounce 1/2"]];
    [_autoLooper startQuantizedBounceLoopHalf];
    [_lblBounceLoop setBackgroundColor:NSColor.systemCyanColor];
    [_lblBounceLoop setDrawsBackground:YES];
}

-(void)startQuantizedBounceLoopQuarter{
    [_lblBounceLoop setStringValue:[NSString stringWithFormat:@"Bounce 1/4"]];
    [_autoLooper startQuantizedBounceLoopQuarter];
    [_lblBounceLoop setBackgroundColor:NSColor.systemCyanColor];
    [_lblBounceLoop setDrawsBackground:YES];
}

-(void)startQuantizedBounceLoopEighth{
    [_lblBounceLoop setStringValue:[NSString stringWithFormat:@"Bounce 1/8"]];
    [_autoLooper startQuantizedBounceLoopEighth];
    [_lblBounceLoop setBackgroundColor:NSColor.systemCyanColor];
    [_lblBounceLoop setDrawsBackground:YES];
}

-(void)startQuantizedBounceLoopSixteenth{
    [_lblBounceLoop setStringValue:[NSString stringWithFormat:@"Bounce 1/16"]];
    [_autoLooper startQuantizedBounceLoopSixteenth];
    [_lblBounceLoop setBackgroundColor:NSColor.systemCyanColor];
    [_lblBounceLoop setDrawsBackground:YES];
}

@end
