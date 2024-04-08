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
#import "MIDI.h"

#import "MainWindow.h"

#import "TurnTableView.h"
#import "MiniFader.h"

#import "MyButton.h"

#import "VolumeGate.h"
#import "TurnTableController.h"
#import "Looper.h"
#import "LooperController.h"
#import "MiscController.h"
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
#import "BeatTrackerController.h"
#import "BeatLookupController.h"
#import "SimpleReverbController.h"
#import "ConvolutionReverbController.h"
#import "PitchShifterController.h"

//OSC
#import "F53OSC.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppController : NSObject <MIDIDelegate, MainWindowKeyDelegate>{
        
    AudioEngine *_ae;
    RingBuffer *_ring;
    MIDI *_midi;
    __weak IBOutlet TurnTableView *_turnTable;
    __weak IBOutlet RingView *_ringView;
    __weak IBOutlet NSTextField *_lblBPM;
    __weak IBOutlet MyButton *_btnTap;
    
    __weak IBOutlet MainWindow *_mainWindow;
    
    NSMutableArray *_tapHistory;
    float _bpm;
    
    float _tempLeftPtr[1024];
    float _tempRightPtr[1024];
    
    MiniFaderIn *_faderIn;
    
    TurnTableController *_turnTableController;
    __weak IBOutlet NSView *_turnTableContentView;
    
    VolumeGate *_volumeGate;
    
    Looper *_looper;
    __weak IBOutlet NSView *_looperContentView;
    LooperController *_looperController;
    __weak IBOutlet NSButton *_btnLooperStart;
    __weak IBOutlet NSButton *_btnLooperEnd;
    __weak IBOutlet NSButton *_btnLooperExit;
    __weak IBOutlet NSButton *_btnLoopHalf;
    __weak IBOutlet NSButton *_btnLoopQuarter;
    
    TrillReverse *_trillReverse;
    Bender *_bender;
    Freezer *_freezer;
    MiscController *_miscController;
    __weak IBOutlet NSView *_miscContentView;
    
    ReverseController *_reverseController;
    Reverse *_reverse;
    __weak IBOutlet NSView *_reverseContentView;
    
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
    __weak IBOutlet NSView *_tapeReverseContentView;
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
    
    Lookup *_lookUp;
    __weak IBOutlet NSView *_lookUpContentView;
    LookUpController *_lookUpController;
    
    BeatTracker *_beatTracker;
    __weak IBOutlet NSView *_beatTrackerContentView;
    BeatTrackerController *_beatTrackerController;
    
    BeatLookup *_beatLookup;
    __weak IBOutlet NSView *_beatLookupContentView;
    BeatLookupController *_beatLookupController;
    
    SimpleReverb *_simpleReverb;
    __weak IBOutlet NSView *_simpleReverbContentView;
    SimpleReverbController *_simpleReverbController;
    
    PitchShifter *_pitchShifter;
    __weak IBOutlet NSView *_pitchShifterContentView;
    PitchShifterController *_pitchShifterController;
    
    NSNetService *_netService;
    F53OSCServer *_oscServer;
    
}

-(void)terminate;
-(void)startBonjour;
-(void)didWakenUp:(NSNotification *)notification;
-(void)MIDIDelegateCC:(Byte)cc data:(Byte)data chan:(Byte)chan;

@end

NS_ASSUME_NONNULL_END
