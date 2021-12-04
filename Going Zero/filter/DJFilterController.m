//
//  DJViewController.m
//  Going Zero
//
//  Created by kyab on 2021/06/05.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "DJFilterController.h"

@implementation DJFilterController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"filterValue"]) {
        if (object == _djFilter){
            [_sliderValue setFloatValue:_djFilter.filterValue];
        }
    }
}


-(void)setDJFilter:(DJFilter *)djFilter{
    _djFilter = djFilter;
    [_djFilter addObserver:self forKeyPath:@"filterValue" options:NSKeyValueObservingOptionNew context:nil];
}

- (IBAction)sliderChanged:(id)sender {
    
    if([[NSApplication sharedApplication] currentEvent].type == NSEventTypeLeftMouseUp){
        [_sliderValue setFloatValue:0];
        [_djFilter setFilterValue:0.0];
        return;
    }
    
    [_djFilter setFilterValue:[_sliderValue floatValue]];
}

@end
