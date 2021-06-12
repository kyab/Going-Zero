//
//  ShooterController.h
//  Going Zero
//
//  Created by kyab on 2021/06/07.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Shooter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShooterController : NSViewController{
    Shooter *_shooter;
    __weak IBOutlet NSButton *_btnShoot;
    __weak IBOutlet NSButton *_btnRec;
    __weak IBOutlet NSSlider *_sliderPitch;
    
    __weak IBOutlet NSSlider *_sliderPan;
}

-(void)setShooter:(Shooter *)shooter;

@end
NS_ASSUME_NONNULL_END
