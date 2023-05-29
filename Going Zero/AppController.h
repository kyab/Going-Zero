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
#import "MiniFader.h"

#import "MyButton.h"
#import "MainViewController.h"

#import "Looper.h"
#import "TrillReverse.h"
#import "Reverse.h"
#import "ReverseController.h"
#import "Bender.h"
#import "Freezer.h"
#import "Viewer.h"
#import "WaveView.h"
#import "Refrain.h"
#import "BitCrasher.h"
#import "BitCrasherController.h"
#import "TapeReverse.h"
#import "TapeReverseController.h"
#import "QuickCue.h"
#import "QuickCueController.h"
#import "Flanger.h"
#import "FlangerController.h"
#import "RefrainController.h"
#import "DJFilterController.h"
#import "SamplerController.h"
#import "RandomController.h"
#import "LookUpController.h"
#import "SimpleReverbController.h"
#import "ConvolutionReverbController.h"

//OSC
#import "F53OSC.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppController : NSObject{
    
    
    __weak IBOutlet MainViewController *_mainViewController;
    
    AudioEngine *_ae;
    RingBuffer *_ring;
    __weak IBOutlet TurnTableView *_turnTable;
    __weak IBOutlet RingView *_ringView;
    __weak IBOutlet NSTextField *_lblBPM;
    __weak IBOutlet MyButton *_btnTap;
    
    NSMutableArray *_tapHistory;
    float _bpm;
    
    float _tempLeftPtr[1024];
    float _tempRightPtr[1024];
    
    double _speedRate;
//    float _dryVolume;
//    float _wetVolume;
    __weak IBOutlet NSSlider *_sliderDryVolume;
    __weak IBOutlet NSSlider *_sliderWetVolume;
    MiniFaderIn *_faderIn;
    
    Looper *_looper;
    __weak IBOutlet NSButton *_btnLooperStart;
    __weak IBOutlet NSButton *_btnLooperEnd;
    __weak IBOutlet NSButton *_btnLooperExit;
    __weak IBOutlet NSButton *_btnLoopHalf;
    __weak IBOutlet NSButton *_btnLoopQuarter;
    
    TrillReverse *_trillReverse;
    __weak IBOutlet NSButton *_chkTrillReverse;

    Bender *_bender;
    __weak IBOutlet NSSlider *_sliderBenderRate;
//    __weak IBOutlet NSButton *_chkBender;
    NSTimer *_benderBounceTimer;
    __weak IBOutlet NSButton *_chkBenderBounce;
    
    
    ReverseController *_reverseController;
    Reverse *_reverse;
    __weak IBOutlet NSView *_reverseContentView;
    
    Freezer *_freezer;
    __weak IBOutlet NSButton *_chkFreeze;
    __weak IBOutlet NSSlider *_sliderGrainSize;
    
    Viewer *_viewer;
    __weak IBOutlet WaveView *_waveView;
    __weak IBOutlet NSButton *_chkWaveViewEnabled;
    
//    
//    __weak IBOutlet NSView *_djContentView;
//    DJViewController *_djViewController;
    
    Refrain *_refrain;
    __weak IBOutlet NSView *_refrainContentView;
    RefrainController *_refrainController;
    
    BitCrasher *_crasher;
    __weak IBOutlet NSView *_crasherContentView;
    BitCrasherController *_crasherController;
    
    TapeReverse *_tapeReverse;
    __weak IBOutlet NSBox *_tapeReverseContentView;
    TapeReverseController *_tapeReverseController;
    
    QuickCue *_quickCue;
    __weak IBOutlet NSView *_quickCueContentView;
    QuickCueController *_quickCueController;
    
    Flanger *_flanger;
    __weak IBOutlet NSView *_flangerContentView;
    FlangerController *_flangerController;
    
    DJFilter *_djFilter;
    __weak IBOutlet NSView *_djFilterContentView;
    DJFilterController *_djFilterController;
    
    Sampler *_sampler;
    __weak IBOutlet NSView *_samplerContentView;
    SamplerController *_samplerController;
    
    Random *_random;
    __weak IBOutlet NSView *_randomContentView;
    RandomController *_randomController;
    
    LookUp *_lookUp;
    __weak IBOutlet NSView *_lookUpContentView;
    LookUpController *_lookUpController;
    
    SimpleReverb *_simpleReverb;
    __weak IBOutlet NSView *_simpleReverbContentView;
    SimpleReverbController *_simpleReverbController;
    
//    ConvolutionReverb *_convolutionReverb;
//    __weak IBOutlet NSView *_convolutionReverbContentView;
//    ConvolutionReverbController *_convolutionReverbController;

    
    NSNetService *_netService;
    F53OSCServer *_oscServer;
    
}

@property (nonatomic) float wetVolume;
@property (nonatomic) float dryVolume;

-(void)terminate;
-(void)startBonjour;
-(void)didWakenUp:(NSNotification *)notification;


@end

NS_ASSUME_NONNULL_END
