//
//  AppController.m
//  Going Zero
//
//  Created by kyab on 2021/05/29.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "AppController.h"
#import <AudioToolbox/AudioToolbox.h>

#include <cmath>

@implementation AppController

-(void)awakeFromNib{
        
    _ring = [[RingBuffer alloc] init];
    [_ringView setRingBuffer:_ring];
    
    [_turnTable setDelegate:(id<TurnTableDelegate>)self];
    [_turnTable setRingBuffer:_ring];
    [_turnTable start];
    
    [_btnTap setKeyEquivalent:@"\t"];
    _tapHistory = [[NSMutableArray alloc] init];
    _bpm = 120.0;
    
    _noteMap = [[NSMutableDictionary alloc] initWithDictionary:@{
        @1:  @(-7.0f), // s -> F
        @14: @(-6.0f), // e -> F#
        @2:  @(-5.0f), // d -> G
        @15: @(-4.0f), // r -> G#
        @3:  @(-3.0f), // f -> A  
        @17: @(-2.0f), // t -> A#
        @5:  @(-1.0f), // g -> B
        @4:  @(0.0f),  // h -> C (center)
        @32: @(1.0f),  // u -> C# 
        @38: @(2.0f),  // j -> D
        @34: @(3.0f),  // i -> D#
        @40: @(4.0f),  // k -> E
        @37: @(5.0f),  // l -> F
        @35: @(6.0f),  // p -> F#
        @41: @(7.0f),  // ; -> G
    }];
    
    _faderIn = [[MiniFaderIn alloc] init];
    
    _turnTableController = [[TurnTableController alloc] initWithNibName:@"TurnTableController" bundle:nil];
    [_turnTableContentView addSubview:[_turnTableController view]];
    [self centerize:[_turnTableController view]];
    
    _beatTracker = [[BeatTracker alloc] init];
    _beatTrackerController = [[BeatTrackerController alloc]
                         initWithNibName:@"BeatTrackerController" bundle:nil];
    [_beatTrackerContentView addSubview:[_beatTrackerController view]];
    [self centerize:[_beatTrackerController view]];
    [_beatTrackerController setBeatTracker:_beatTracker];
    
    _beatLookup = [[BeatLookup alloc] init];
    _beatLookupController = [[BeatLookupController alloc]
                         initWithNibName:@"BeatLookupController" bundle:nil];
    [_beatLookupContentView addSubview:[_beatLookupController view]];
    [self centerize:[_beatLookupController view]];
    [_beatLookupController setBeatLookup:_beatLookup];
    [_beatLookup setBeatTracker:_beatTracker];

    _melodizer = [[Melodizer alloc] init];
    _melodizerController = [[MelodizerController alloc] initWithNibName:@"MelodizerController" bundle:nil];
    [_melodizerContentView addSubview:[_melodizerController view]];
    [self centerize:[_melodizerController view]];
    [_melodizerController setMelodizer:_melodizer];
    
    _volumeGate = [[VolumeGate alloc] init];
    
    _autoLooper = [[AutoLooper alloc] init];
    _autoLooperController = [[AutoLooperController alloc] initWithNibName:@"AutoLooperController" bundle:nil];
    [_autoLooperContentView addSubview:[_autoLooperController view]];
    [self centerize:[_autoLooperController view]];
    [_autoLooperController setAutoLooper:_autoLooper];
    [_autoLooper setBeatTracker:_beatTracker];
    
    _looper = [[Looper alloc] init];
    _looperController = [[LooperController alloc] initWithNibName:@"LooperController" bundle:nil];
    [_looperContentView addSubview:[_looperController view]];
    [self centerize:[_looperController view]];
    [_looperController setLooper:_looper];
    
    _pitch = [[Pitch alloc] init];
    _pitchController = [[PitchController alloc] initWithNibName:@"PitchController" bundle:nil];
    [_pitchContentView addSubview:[_pitchController view]];
    [self centerize:[_pitchController view]];
    [_pitchController setPitch:_pitch];
    
    _trillReverse = [[TrillReverse alloc] init];
    _bender = [[Bender alloc] init];
    _freezer = [[Freezer alloc] init];
    _miscController = [[MiscController alloc] initWithNibName:@"MiscController" bundle:nil];
    [_miscContentView addSubview:[_miscController view]];
    [self centerize:[_miscController view]];
    [_miscController setBender:_bender];
    [_miscController setTrillReverse:_trillReverse];
    [_miscController setFreezer:_freezer];
    
    
    _reverse = [[Reverse alloc] init];
    _reverseController = [[ReverseController alloc] initWithNibName:@"ReverseController" bundle:nil];
    [_reverseContentView addSubview:[_reverseController view]];
    [self centerize:[_reverseController view]];
    [_reverseController setReverse:_reverse];
        
    _inViewer = [[Viewer alloc] init];
    [_inViewer setExternalRing:_ring];
    [_inWaveView setViewer:_inViewer];
    [_inViewer setEnabled:YES];
    
    _viewer = [[Viewer alloc] init];
    [_waveView setViewer: _viewer];
    [_viewer setEnabled:YES];
    
    _refrain = [[Refrain alloc] init];
    _refrainController = [[RefrainController alloc] initWithNibName:@"RefrainView" bundle:nil];
    [_refrainContentView addSubview:[_refrainController view]];
    [self centerize:[_refrainController view]];
    [_refrainController setRefrain:_refrain];
    
    _crusher = [[BitCrusher alloc] init];
    _crusherController = [[BitCrusherController alloc] initWithNibName:@"BitCrusherController" bundle:nil];
    [_crusherContentView addSubview:[_crusherController view]];
    [self fitView:[_crusherController view]];
    [_crusherController setBitCrusher:_crusher];
    
    _tapeReverse = [[TapeReverse alloc] init];
    _tapeReverseController = [[TapeReverseController alloc] initWithNibName:@"TapeReverseController" bundle: nil];
    [_tapeReverseContentView addSubview:[_tapeReverseController view]];
    [self centerize:[_tapeReverseController view]];
    [_tapeReverseController setTapeReverse:_tapeReverse];
    
    _quickCue = [[QuickCue alloc] init];
    _quickCueController = [[QuickCueController alloc] initWithNibName:@"QuickCueController" bundle:nil];
    [_quickCueContentView addSubview:[_quickCueController view]];
    [self centerize:[_quickCueController view]];
    [_quickCueController setQuickCue:_quickCue];
    
    _flanger = [[Flanger alloc] init];
    _flangerController = [[FlangerController alloc] initWithNibName:@"FlangerController" bundle:nil];
    [_flangerContentView addSubview:[_flangerController view]];
    [self centerize:[_flangerController view]];
    [_flangerController setFlanger:_flanger];
    
    _sampler = [[Sampler alloc] init];
    _samplerController = [[SamplerController alloc]
                           initWithNibName:@"SamplerController" bundle:nil];
    [_samplerContentView addSubview:[_samplerController view]];
    [self centerize:[_samplerController view]];
    [_samplerController setSampler:_sampler];
    
    _random = [[Random alloc] init];
    _randomController = [[RandomController alloc]
                         initWithNibName:@"RandomController" bundle:nil];
    [_randomContentView addSubview:[_randomController view]];
    [self fitView:[_randomController view]];
    [_random setBeatTracker:_beatTracker];
    [_randomController setRandom:_random];
    
    _lookUp = [[Lookup alloc] init];
    _lookUpController = [[LookUpController alloc]
                         initWithNibName:@"LookUpController" bundle:nil];
    [_lookUpContentView addSubview:[_lookUpController view]];
    [self centerize:[_lookUpController view]];
    [_lookUpController setLookUp:_lookUp];
    
    _simpleReverb = [[SimpleReverb alloc] init];
    _simpleReverbController = [[SimpleReverbController alloc]
                         initWithNibName:@"SimpleReverbController" bundle:nil];
    [_simpleReverbContentView addSubview:[_simpleReverbController view]];
    [self centerize:[_simpleReverbController view]];
    [_simpleReverbController setSimpleReverb:_simpleReverb];
    
    _djFilter = [[DJFilter alloc] init];
    _djFilterController = [[DJFilterController alloc]
                           initWithNibName:@"DJFilterController" bundle:nil];
    [_djFilterContentView addSubview:[_djFilterController view]];
    [self centerize:[_djFilterController view]];
    [_djFilterController setDJFilter:_djFilter];
    
    [self startBonjour];
    
    _midi = [[MIDI alloc] init];
    [_midi setup];
    [_midi setDelegate:self];
    
    [_mainWindow setKeyDelegate:self];
    
    _ae = [[AudioEngine alloc] init];
    if ([_ae initialize]){
        NSLog(@"AudioEngine all OK");
    }
    [_ae setRenderDelegate:(id<AudioEngineDelegate>)self];
    
    NSLog(@"!!!!!!!!!!Changing system output device to BGM...");
    [_ae changeSystemOutputDeviceToBGM];
    NSLog(@"!!!!!!!!!!!!Changing system output device to BGM...done");
    
    [_ae startOutput];
    [_ae startInput];
    
    //wake up
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(didWakenUp:) name:NSWorkspaceDidWakeNotification object:nil];
    
}

-(void)MIDIDelegateNoteOn:(Byte)note vel:(Byte)vel chan:(Byte)chan{
    if (note == 77){
        UInt32 beatRegionDivide16 = (UInt32)((float)vel / (127.0f/16.0));
        [_beatLookup startBeatJuggling:beatRegionDivide16];
    }
    NSLog(@"MIDI : note on:%d data:%d chan:%d", note, vel, chan+1);
}

-(void)MIDIDelegateNoteOff:(Byte)note vel:(Byte)vel chan:(Byte)chan{
    if (note == 77){
        [_beatLookup stopBeatJuggling];
    }
    NSLog(@"MIDI : note off:%d data:%d chan:%d", note, vel, chan+1);
}

-(void)MIDIDelegateCC:(Byte)cc data:(Byte)data chan:(Byte)chan{
    NSLog(@"MIDI : cc:%d data:%d chan:%d", cc, data, chan+1);
    
    // Handle CC 64 (Hold/Sustain pedal) for Freezer control
    if (cc == 64) {
        if (data != 0) {
            // Turn Freezer On (UI will be updated via KVO)
            [_freezer setActive:YES];
        } else {
            // Turn Freezer Off (UI will be updated via KVO)
            [_freezer setActive:NO];
        }
    }
}

-(void)terminate{
    [_ae stopOutput];
    [_ae stopInput];
    [_ae restoreSystemOutputDevice];
}

-(void)centerize:(NSView *)view{
    NSView *superView = view.superview;
    NSPoint origin = NSMakePoint(
        (superView.frame.size.width - view.frame.size.width)/2,
        (superView.frame.size.height - view.frame.size.height)/2);
    [view setFrameOrigin:origin];
    
    [view setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin];
    
}

-(void)fitView:(NSView *)view{
    NSView *superView = view.superview;
    [view setFrameSize:superView.frame.size];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
}


//- (OSStatus) inCallback:(AudioUnitRenderActionFlags *)ioActionFlags inTimeStamp:(const AudioTimeStamp *) inTimeStamp inBusNumber:(UInt32) inBusNumber inNumberFrames:(UInt32)inNumberFrames /*ioData:(AudioBufferList *)ioData*/{
//    
//    static int count = 0;
//    
//    static BOOL printNumFrames = NO;
//    if (!printNumFrames){
//        NSLog(@"First inCallback NumFrames = %d", inNumberFrames);
//        printNumFrames = YES;
//    }
//    
//    AudioBufferList *bufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList) +  sizeof(AudioBuffer)); // for 2 buffers for left and right
//    
//    float *leftPrt = [_ring writePtrLeft];
//    float *rightPtr = [_ring writePtrRight];
//    
//    bufferList->mNumberBuffers = 2;
//    bufferList->mBuffers[0].mDataByteSize = 32*inNumberFrames;
//    bufferList->mBuffers[0].mNumberChannels = 1;
//    bufferList->mBuffers[0].mData = leftPrt;
//    bufferList->mBuffers[1].mDataByteSize = 32*inNumberFrames;
//    bufferList->mBuffers[1].mNumberChannels = 1;
//    bufferList->mBuffers[1].mData = rightPtr;
//    
//    
//    OSStatus ret = [_ae readFromInput:ioActionFlags inTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames ioData:bufferList];
//    
//    free(bufferList);
//    
//    if ([_ae isRecording]){
//        [_ring advanceWritePtrSample:inNumberFrames];
//        count += inNumberFrames;
//        if (count >= 44100){
//            NSLog(@"I");
//            count = 0;
//        }
//    }
//    
//    return ret;
//    
//}

-(void)audioInCallback:(UInt32)inNumberframes bufferList:(AudioBufferList *)bufferList{
    float *leftPtr = [_ring writePtrLeft];
    float *rightPtr = [_ring writePtrRight];
    
    memcpy(leftPtr, bufferList->mBuffers[0].mData, sizeof(float)*inNumberframes);
    memcpy(rightPtr, bufferList->mBuffers[1].mData, sizeof(float)*inNumberframes);
    
    if ([_ae isRecording]){
        [_ring advanceWritePtrSample:inNumberframes];
    }
    
}

- (OSStatus) outCallback:(AudioUnitRenderActionFlags *)ioActionFlags inTimeStamp:(const AudioTimeStamp *) inTimeStamp inBusNumber:(UInt32) inBusNumber inNumberFrames:(UInt32)inNumberFrames ioData:(AudioBufferList *)ioData{
    
    static int count = 0;
    static BOOL printedNumFrames = NO;
    static BOOL followRequired = YES;
    if (!printedNumFrames){
        NSLog(@"First outCallback. NumFrames = %d", inNumberFrames);
        printedNumFrames = YES;
    }
    
    
    if (![_ae isPlaying]){
        UInt32 sampleNum = inNumberFrames;
        float *pLeft = (float *)ioData->mBuffers[0].mData;
        float *pRight = (float *)ioData->mBuffers[1].mData;
        bzero(pLeft,sizeof(float)*sampleNum );
        bzero(pRight,sizeof(float)*sampleNum );
        NSLog(@"Not playing");
        followRequired = YES;
        return noErr;
    }
    
    if ([_ring isShortage]){
        UInt32 sampleNum = inNumberFrames;
        float *pLeft = (float *)ioData->mBuffers[0].mData;
        float *pRight = (float *)ioData->mBuffers[1].mData;
        bzero(pLeft,sizeof(float)*sampleNum );
        bzero(pRight,sizeof(float)*sampleNum );
//        followRequired = YES;
        NSLog(@"shortage in out thread");
        return noErr;
    }
    
    if (![_ring dryPtrLeft] || ![_ring dryPtrRight]){
        // not enough buffer
        NSLog(@"no enough buffer on dry");
        UInt32 sampleNum = inNumberFrames;
        float *pLeft = (float *)ioData->mBuffers[0].mData;
        float *pRight = (float *)ioData->mBuffers[1].mData;
        bzero(pLeft, sizeof(float)*sampleNum );
        bzero(pRight, sizeof(float)*sampleNum );
        followRequired = YES;
        return noErr;
     }
    
    if (followRequired){
        [_ring follow];
        NSLog(@"Follow");
        followRequired = NO;
    }
    
    // Audio input → ioData (pass-through from AppController's ring)
    memcpy((float *)ioData->mBuffers[0].mData, [_ring dryPtrLeft], sizeof(float) * inNumberFrames);
    memcpy((float *)ioData->mBuffers[1].mData, [_ring dryPtrRight], sizeof(float) * inNumberFrames);
    [_ring advanceDryPtrSample:inNumberFrames];
    [_ring advanceReadPtrSample:inNumberFrames];
    [_faderIn processLeft:(float *)ioData->mBuffers[0].mData
                    right:(float *)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //Melodizer (introduce some latency so should be head)
    [_melodizer processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];

    //TurnTable
    [_turnTableController processLeft:(float *)ioData->mBuffers[0].mData
                                right:(float *)ioData->mBuffers[1].mData
                              samples:inNumberFrames];
    
    // Pitch
    [_pitch processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //beat tracker
    [_beatTracker processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //Auto Looper
    [_autoLooper processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //Volume Gate
    [_volumeGate processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //Beat Lookup
    [_beatLookup processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];

    
    //Trill reverse
    [_trillReverse processLeft:(float*)ioData->mBuffers[0].mData
                         right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];

    //Freezer
    [_freezer processLeft:(float*)ioData->mBuffers[0].mData
                    right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //Sampler
    [_sampler processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];

    //Random
    [_random processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    
    //LookUp
    [_lookUp processLeft:(float*)ioData->mBuffers[0].mData
                   right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //Looper
    [_looper processLeft:(float*)ioData->mBuffers[0].mData
                         right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];

    //Quick Cue
    [_quickCue processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //Bender
    [_bender processLeft:(float*)ioData->mBuffers[0].mData
                         right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
  
    //Reverse
    [_reverse processLeft:(float*)ioData->mBuffers[0].mData
                         right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //Refrain
    [_refrain processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //Bit crusher
    [_crusher processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
  
    //Tape reverse
    [_tapeReverse processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //Flanger
    [_flanger processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //DJ filter
    [_djFilter processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //Simple Reverb
    [_simpleReverb processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //Viewer
    [_viewer processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];

    
    return noErr;
}

static double linearInterporation(int x0, double y0, int x1, double y1, double x){
    if (x0 == x1){
        return y0;
    }
    double rate = (x - x0) / (x1 - x0);
    double y = (1.0 - rate)*y0 + rate*y1;
    return y;
}


-(void)convertAtRateFromLeft:(float *)leftPtr right:(float *)rightPtr ToSamples:(UInt32)inNumberFrames rate:(double)rate consumedFrames:(SInt32 *)consumed{
    if (rate == 1.0 || rate==0.0 || rate ==-0.0){
        [self convertAtRatePlusFromLeft:leftPtr right:rightPtr ToSamples:inNumberFrames rate:rate consumedFrames:consumed];
    }else{
        [self convertAtRatePlusFromLeft:leftPtr right:rightPtr ToSamples:inNumberFrames rate:rate consumedFrames:consumed];
    }
}

-(void)convertAtRatePlusFromLeft:(float *)leftPtr right:(float *)rightPtr ToSamples:(UInt32)inNumberFrames rate:(double)rate consumedFrames:(SInt32 *)consumed{
    
    *consumed = 0;
    
    for (int targetSample = 0; targetSample < inNumberFrames; targetSample++){
        int x0 = floor(targetSample*rate);
        int x1 = ceil(targetSample*rate);
        
        float y0_l = leftPtr[x0];
        float y1_l = leftPtr[x1];
        float y_l = linearInterporation(x0, y0_l, x1, y1_l, targetSample*rate);
        
        float y0_r = rightPtr[x0];
        float y1_r = rightPtr[x1];
        float y_r = linearInterporation(x0, y0_r, x1, y1_r, targetSample*rate);
        
        _tempLeftPtr[targetSample] = y_l;
        _tempRightPtr[targetSample] = y_r;
        *consumed = x1;
    }
}

//- (IBAction)monitorEnableChanged:(id)sender {
//    if ([_chkWaveViewEnabled state] == NSControlStateValueOn){
//        [_viewer setEnabled:YES];
//    }else{
//        [_viewer setEnabled:NO];
//    }
//}

-(void)startBonjour{
    
    _netService = [[NSNetService alloc] initWithDomain:@"local" type:@"_osc._udp" name:@"" port:9999];

    [_netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [_netService publish];
//    [_netService setDelagete:self];
    
    _oscServer = [[F53OSCServer alloc] init];

    [_oscServer setPort:17171];
    [_oscServer setDelegate:(id<F53OSCServerDelegate>)self];
    [_oscServer startListening];
    
    
}

- (void)takeMessage:(F53OSCMessage *)message {
//    NSLog(@"Received");
    // This method is called whenever the oscServer receives a message.
    NSString *addressPattern = message.addressPattern;
    NSArray *arguments = message.arguments;
//    NSLog(@"%@", addressPattern);
    
    NSObject *arg1 = [arguments objectAtIndex:0];
    
    if ([addressPattern isEqualToString:@"/filter/"]){
        if ([arg1 isKindOfClass:[NSNumber class]]){
            NSNumber *number = (NSNumber *)arg1;
            float f = [number floatValue];
            _djFilter.filterValue = f;
        }
    }else if([addressPattern isEqualToString:@"/loop/"]){
        if ([arg1 isKindOfClass:[NSString class]]){
            NSString *str  = (NSString *)arg1;
//            NSLog(@"loop:%@",str);
            if([str isEqualToString:@"start"]){
                [_btnLooperStart performClick:_btnLooperStart];
            }else if ([str isEqualToString:@"end"]){
                [_btnLooperEnd performClick:_btnLooperEnd];
            }else if ([str isEqualToString:@"exit"]){
                [_btnLooperExit performClick:_btnLooperExit];
            }else if ([str isEqualToString:@"half"]){
                [_btnLoopHalf performClick:_btnLoopHalf];
            }else if ([str isEqualToString:@"quarter"]){
                [_btnLoopQuarter performClick:_btnLoopQuarter];
            }
        }
    }else if ([addressPattern isEqualToString:@"/turntable/speed"]){
        if ([arg1 isKindOfClass:[NSNumber class]]){
            NSNumber *number = (NSNumber *)arg1;
            float f = [number floatValue];
            NSLog(@"new speed rate = %f", f);
//            _speedRate = f;
//            if (_speedRate == 1.0){
//                [_ring follow];
//            }
        }
    }else if ([addressPattern isEqualToString:@"/turntable/wet"]){
        if ([arg1 isKindOfClass:[NSNumber class]]){
//            NSNumber *number = (NSNumber *)arg1;
//            self.wetVolume = [number floatValue];
        }
    }else if ([addressPattern isEqualToString:@"/turntable/dry"]){
        if ([arg1 isKindOfClass:[NSNumber class]]){
//            NSNumber *number = (NSNumber *)arg1;
//            self.dryVolume = [number floatValue];
        }
    }
}

- (IBAction)tapClicked:(id)sender {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    
    if (_tapHistory.count >= 8){
        [_tapHistory removeObjectAtIndex:0];
    }
    
    [_tapHistory addObject:[NSNumber numberWithDouble:now]];
    if (_tapHistory.count >=4){
        double from = [[_tapHistory objectAtIndex:0] doubleValue];
        double to = [[_tapHistory lastObject] doubleValue];
        double bpm = 60.0/((to-from)/(_tapHistory.count-1));
        
        if (bpm > 60.0){
            _bpm = bpm;
            [_lblBPM setStringValue:[NSString stringWithFormat:@"%.02f",_bpm]];
//            [_random setBPM:bpm];
        }
    }

}

-(void)didWakenUp:(NSNotification *)notification{
    NSLog(@"didWakenUp");
//    [_ring follow];
}

-(Boolean)mainWindowKeyDown:(NSEvent *)event{

    //Melodizer
    if ([_noteMap objectForKey:[NSNumber numberWithInt:event.keyCode]]){
        if (!event.isARepeat){
            _lastNoteKeyCode = event.keyCode;
            float pitchShift = [[_noteMap objectForKey:[NSNumber numberWithInt:event.keyCode]] floatValue];
            [_melodizerController setTranspose:pitchShift];
        }
        return YES;
    }

    switch(event.keyCode){
        case 12: // q
            if (!event.isARepeat){
                if (event.modifierFlags & NSEventModifierFlagShift){
                    [_autoLooperController startQuantizedAutoLoop];
                }else{
                    [_autoLooperController toggleQuantizedLoop];
                }
            }
            return YES;
        case 13: // w
            if (!event.isARepeat){
                [_autoLooper halveLoopLength];
                [_autoLooperController refreshLoopLabel];
            }
            return YES;
        case 14: // e
            if (!event.isARepeat){
                [_autoLooper doubleLoopLength];
                [_autoLooperController refreshLoopLabel];
            }
            return YES;
        case 11: //b
            if (!event.isARepeat){
                [_random start];
            }
            return YES;
        case 26: //7
            if (!event.isARepeat){
                [_autoLooperController startQuantizedBounceLoopQuad];
            }
            return YES;
        case 22: //6
            if (!event.isARepeat){
                [_autoLooperController startQuantizedBounceLoopDouble];
            }
            return YES;
        case 23: //5
            if (!event.isARepeat){
                [_autoLooperController startQuantizedBounceLoop];
            }
            return YES;
        case 21: //4
            if (!event.isARepeat){
                [_autoLooperController startQuantizedBounceLoopHalf];
            }
            return YES;
        case 20: //3
            if (!event.isARepeat){
                [_autoLooperController startQuantizedBounceLoopQuarter];
            }
            return YES;
        case 19: //2
            if (!event.isARepeat){
                [_autoLooperController startQuantizedBounceLoopEighth];
            }
            return YES;
        case 18: //1
            if (!event.isARepeat){
                [_autoLooperController startQuantizedBounceLoopSixteenth];
            }
            return YES;
        case 46: // m
            if (!event.isARepeat){
                [_volumeGate activate];
            }
            return YES;
        case 49: // space
            if (!event.isARepeat){
                [_volumeGate openGate];
            }
            return YES;
        default:
            break;
    }
    
    return NO;
}

-(Boolean)mainWindowKeyUp:(NSEvent *)event{

    //Melodizer
    if ([_noteMap objectForKey:[NSNumber numberWithInt:event.keyCode]]){
        if (_lastNoteKeyCode == event.keyCode){
            [_melodizerController stopTranspose];
            return YES;
        }
    }

    switch(event.keyCode){
        case 12: // q
        case 13: // w
        case 14: // e
            return YES;
        case 26:
        case 22:
        case 23:
        case 21:
        case 20:
        case 19:
        case 18:
            [_autoLooperController exitLoop];
            return YES;
        case 46: // m
            [_volumeGate deactivate];
            return YES;
        case 49: // space
            [_volumeGate closeGate];
            return YES;
        default:
            break;
    }
    return NO;
}


@end
