//
//  SamplerController.m
//  Going Zero
//
//  Created by kyab on 2021/11/14.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "SamplerController.h"

@interface SamplerController ()

@end

@implementation SamplerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    _btnShots[0] = _btnShot1;
    _btnShots[1] = _btnShot2;
    _btnShots[2] = _btnShot3;
    _btnShots[3] = _btnShot4;
}

-(UInt32)getIndex:(id)sender{
    if (sender == _btnShot1 || sender == _btnClear1){
        return 0;
    }else if (sender == _btnShot2 || sender == _btnClear2){
        return 1;
    }else if (sender == _btnShot3 || sender == _btnClear3){
        return 2;
    }else if (sender == _btnShot4 || sender == _btnClear4){
        return 3;
    }
    return 0;
}

-(void)setSampler:(Sampler *)sampler{
    _sampler = sampler;
    [_sampler setDelegate:self];
}

- (IBAction)shotClicked:(id)sender {
    UInt32 index = [self getIndex:sender];
    switch([_sampler state:index]){
        case SAMPLER_STATE_EMPTY:
            [_sampler startRecord:index];
            break;
        case SAMPLER_STATE_RECORDING:
            [_sampler stopRecord:index];
            break;
        case SAMPLER_STATE_READYPLAY:
            [_sampler play:index];
            break;
        case SAMPLER_STATE_PLAYING:
            [_sampler play:index];
            break;
        default:
            break;
    }
    
}

- (IBAction)clearClicked:(id)sender {
    UInt32 index = [self getIndex:sender];
    
    [_sampler clear:index];
}

- (IBAction)exitClicked:(id)sender {
    [_sampler exit];
}

-(void)samplerStateChanged:(UInt32)index{
    switch([_sampler state:index]){
        case SAMPLER_STATE_EMPTY:
            [_btnShots[index] setState:NSControlStateValueOff];
            [_btnShots[index] setTitle:@"Rec"];
            break;
        case SAMPLER_STATE_RECORDING:
            [_btnShots[index] setState:NSControlStateValueOff];
            [_btnShots[index] setTitle:@"Stop"];
            break;
        case SAMPLER_STATE_READYPLAY:
            [_btnShots[index] setState:NSControlStateValueOn];
            [_btnShots[index] setTitle:@"Play"];
            break;
        case SAMPLER_STATE_PLAYING:
            [_btnShots[index] setState:NSControlStateValueOn];
            [_btnShots[index] setTitle:@"More"];
            break;
        default:
            break;
    }
}

- (IBAction)dryVolumeChanged:(id)sender {
    [_sampler setDryVolume:[_sliderDryVolume floatValue]];
}




@end
