//
//  AppController.h
//  Going Zero
//
//  Created by kyab on 2021/05/29.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "AudioEngine.h"
#import "RingBuffer.h"
#import "RingView.h"
#import "TurnTableView.h"
#import "Looper.h"
#import "TrillReverse.h"
#import "Bender.h"
#import "Freezer.h"
#import "Viewer.h"
#import "WaveView.h"
#import "Sampler.h"
#import "Refrain.h"
#import "BitCrasher.h"
#import "BitCrasherController.h"
#import "Shooter.h"
#import "ShooterController.h"
#import "TapeReverse.h"
#import "TapeReverseController.h"

#import "DJViewController.h"
#import "RefrainController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppController : NSObject{
    AudioEngine *_ae;
    RingBuffer *_ring;
    __weak IBOutlet TurnTableView *_turnTable;
    __weak IBOutlet RingView *_ringView;
    
    float _tempLeftPtr[1024];
    float _tempRightPtr[1024];
    
    double _speedRate;
    float _dryVolume;
    float _wetVolume;
    __weak IBOutlet NSSlider *_sliderDryVolume;
    
    Looper *_looper;
    
    TrillReverse *_trillReverse;
    __weak IBOutlet NSButton *_chkTrillReverse;

    Bender *_bender;
    __weak IBOutlet NSSlider *_sliderBenderRate;
//    __weak IBOutlet NSButton *_chkBender;
    NSTimer *_benderBounceTimer;
    __weak IBOutlet NSButton *_chkBenderBounce;
    
    Freezer *_freezer;
    __weak IBOutlet NSButton *_chkFreeze;
    
    Viewer *_viewer;
    __weak IBOutlet WaveView *_waveView;
    
    Sampler *_sampler;
    __weak IBOutlet NSButton *_btnSampler;
    __weak IBOutlet NSSlider *_sliderSamplerPan;
    
    
    __weak IBOutlet NSView *_djContentView;
    DJViewController *_djViewController;
    
    Refrain *_refrain;
    __weak IBOutlet NSView *_refrainContentView;
    RefrainController *_refrainController;
    
    BitCrasher *_crasher;
    __weak IBOutlet NSView *_crasherContentView;
    BitCrasherController *_crasherController;
    
    Shooter *_shooter;
    __weak IBOutlet NSView *_shooterContentView;
    ShooterController *_shooterController;
    
    TapeReverse *_tapeReverse;
    __weak IBOutlet NSBox *_tapeReverseContentView;
    TapeReverseController *_tapeReverseController;
    
    
}
-(void)terminate;


@end

NS_ASSUME_NONNULL_END
