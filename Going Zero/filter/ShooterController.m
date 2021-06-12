//
//  ShooterController.m
//  Going Zero
//
//  Created by kyab on 2021/06/07.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "ShooterController.h"

@interface ShooterController ()

@end

@implementation ShooterController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)setShooter:(Shooter *)shooter{
    _shooter = shooter;
}

- (IBAction)onShoot:(id)sender {
    [_shooter shoot];
}

- (IBAction)pitchChanged:(id)sender {
    float val = _sliderPitch.floatValue;

    if (val==0.0){
        [_shooter setPitch:1.0];
    }else if (val > 0.0){
        [_shooter setPitch:1.0 + val];
    }else {
        
        float pitch = 0.5 + (1.0+val)/2;
        [_shooter setPitch:pitch];
        
    }
    
}

- (IBAction)panChanged:(id)sender {
    [_shooter setPan:_sliderPan.floatValue];
}




- (IBAction)onRecord:(id)sender {
    [_shooter recOrExit];
    switch([_shooter state]){
        case SHOOTER_STATE_RECORDING:
            [_btnRec setTitle:@"Stop"];
            break;
        case SHOOTER_STATE_READY:
            [_btnRec setTitle:@"Exit"];
            break;
        case SHOOTER_STATE_NONE:
            [_btnRec setTitle:@"Record"];
            break;
        default:
            break;
    }
}

@end
