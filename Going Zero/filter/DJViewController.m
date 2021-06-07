//
//  DJViewController.m
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "DJViewController.h"

@interface DJViewController ()

@end

@implementation DJViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"DJViewController::viewDidLoad");
    // Do view setup here.
}



- (IBAction)sliderChanged:(id)sender {
    
    NSString *str = [NSString stringWithFormat:@"%f", [_sliderValue floatValue]];
    
    [_label setStringValue:str];

    
    NSEvent *e = NSApplication.sharedApplication.currentEvent;
    if (e.type == NSEventTypeLeftMouseUp){
        [_label setStringValue:@""];
    }
    
    CGFloat max = _sliderValue.maxValue;
    CGFloat min = _sliderValue.minValue;
    CGFloat current = _sliderValue.floatValue;
    CGFloat ratio = current/(max-min);
    
    CGFloat x = ratio * _sliderValue.cell.controlView.frame.size.width;
    [_label.cell.controlView setFrameOrigin:NSMakePoint(x,30)];
}

- (IBAction)buttonClicked:(id)sender {
    NSLog(@"click");
}

@end
