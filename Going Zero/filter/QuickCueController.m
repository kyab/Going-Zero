//
//  QuickCueController.m
//  Going Zero
//
//  Created by kyab on 2021/06/15.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "QuickCueController.h"

@interface QuickCueController ()

@end

@implementation QuickCueController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _btnCues[0] = _btnCue1;
    _btnCues[1] = _btnCue2;
}

-(void)setQuickCue:(QuickCue *)quickCue{
    _quickCue = quickCue;
    
}

-(UInt32)getIndex:(id)sender{
    if (sender == _btnCue1 || sender == _btnClear1){
        return 0;
    }else if (sender == _btnCue2 || sender == _btnClear2){
        return 1;
    }
    return 0;
}

- (IBAction)cueClicked:(id)sender {
    UInt32 index = [self getIndex:sender];
    NSButton *btn = (NSButton *)sender;
    
    switch([_quickCue state:index]){
    case QUICKCUE_STATE_NONE:
        [_quickCue mark:index];
        [btn setState:NSControlStateValueOn];
        break;
    case QUICKCUE_STATE_MARKED:
    case QUICKCUE_STATE_PLAYING:
        [_quickCue play:index];
        [btn setState:NSControlStateValueOn];
        break;
    default:
        break;
    }
    
}

- (IBAction)clearClicked:(id)sender {
    UInt32 index = [self getIndex:sender];
    NSButton *btn = _btnCues[index];
    
    [_quickCue clear:index];
    [btn setState:NSControlStateValueOff];
    
}

- (IBAction)exitClicked:(id)sender {
    [_quickCue exit];
}


@end
