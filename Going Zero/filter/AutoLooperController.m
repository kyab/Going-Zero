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
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

-(void)onTimer:(NSTimer *)timer{
    if (![_autoLooper isLooping]){
        [self exitLoopUI];
    }
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
    [self exitLoopUI];
}

-(void)exitLoopUI{
    [_lblLoop setBackgroundColor:NSColor.textBackgroundColor];
    [_lblLoop setDrawsBackground:NO];
    [_lblBounceLoop setStringValue:[NSString stringWithFormat:@"Bounce"]];
    [_lblBounceLoop setBackgroundColor:NSColor.textBackgroundColor];
    [_lblBounceLoop setDrawsBackground:NO];
    [_lblAutoLoop setBackgroundColor:NSColor.textBackgroundColor];
    [_lblAutoLoop setDrawsBackground:NO];
}

-(void)toggleQuantizedLoop{
    if ([_autoLooper isLooping]){
        [self exitLoop];
    }else{
        [self exitLoop];
        [_lblLoop setBackgroundColor:NSColor.systemIndigoColor];
        [_lblLoop setDrawsBackground:YES];
        [_autoLooper startQuantizedNormalLoop];
    }
}

-(void)startQuantizedAutoLoop{
    [self exitLoop];
    [_autoLooper startQuantizedAutoLoop];
    [_lblAutoLoop setBackgroundColor:NSColor.systemIndigoColor];
    [_lblAutoLoop setDrawsBackground:YES];
}

-(void)startQuantizedBounceLoopDouble{
    [self exitLoop];
    [_lblBounceLoop setStringValue:[NSString stringWithFormat:@"Bounce 2"]];
    [_autoLooper startQuantizedBounceLoopDouble];
    [_lblBounceLoop setBackgroundColor:NSColor.systemIndigoColor];
    [_lblBounceLoop setDrawsBackground:YES];
}

-(void)startQuantizedBounceLoop{
    [self exitLoop];
    [_lblBounceLoop setStringValue:[NSString stringWithFormat:@"Bounce 1"]];
    [_autoLooper startQuantizedBounceLoop];
    [_lblBounceLoop setBackgroundColor:NSColor.systemIndigoColor];
    [_lblBounceLoop setDrawsBackground:YES];
}

-(void)startQuantizedBounceLoopHalf{
    [self exitLoop];
    [_lblBounceLoop setStringValue:[NSString stringWithFormat:@"Bounce 1/2"]];
    [_autoLooper startQuantizedBounceLoopHalf];
    [_lblBounceLoop setBackgroundColor:NSColor.systemIndigoColor];
    [_lblBounceLoop setDrawsBackground:YES];
}

-(void)startQuantizedBounceLoopQuarter{
    [self exitLoop];
    [_lblBounceLoop setStringValue:[NSString stringWithFormat:@"Bounce 1/4"]];
    [_autoLooper startQuantizedBounceLoopQuarter];
    [_lblBounceLoop setBackgroundColor:NSColor.systemIndigoColor];
    [_lblBounceLoop setDrawsBackground:YES];
}

-(void)startQuantizedBounceLoopEighth{
    [self exitLoop];
    [_lblBounceLoop setStringValue:[NSString stringWithFormat:@"Bounce 1/8"]];
    [_autoLooper startQuantizedBounceLoopEighth];
    [_lblBounceLoop setBackgroundColor:NSColor.systemIndigoColor];
    [_lblBounceLoop setDrawsBackground:YES];
}

-(void)startQuantizedBounceLoopSixteenth{
    [self exitLoop];
    [_lblBounceLoop setStringValue:[NSString stringWithFormat:@"Bounce 1/16"]];
    [_autoLooper startQuantizedBounceLoopSixteenth];
    [_lblBounceLoop setBackgroundColor:NSColor.systemIndigoColor];
    [_lblBounceLoop setDrawsBackground:YES];
}

@end
