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
    
    _speedRate = 1.0;
    [_turnTable setDelegate:(id<TurnTableDelegate>)self];
    [_turnTable setRingBuffer:_ring];
    [_turnTable start];
    _dryVolume = 0.0;
    _wetVolume = 1.0;
    [self addObserver:self forKeyPath:@"dryVolume" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"wetVolume" options:NSKeyValueObservingOptionNew context:nil];
    
    [_btnTap setKeyEquivalent:@"\t"];
    _tapHistory = [[NSMutableArray alloc] init];
    _bpm = 120.0;
    
    _faderIn = [[MiniFaderIn alloc] init];
    
    _beatTracker = [[BeatTracker alloc] init];
    _beatTrackerController = [[BeatTrackerController alloc]
                         initWithNibName:@"BeatTrackerController" bundle:nil];
    [_beatTrackerContentView addSubview:[_beatTrackerController view]];
    [self centerize:[_beatTrackerController view]];
    [_beatTrackerController setBeatTracker:_beatTracker];
    
    _looper = [[Looper alloc] init];
    
    _trillReverse = [[TrillReverse alloc] init];
    _bender = [[Bender alloc] init];
    
    _reverse = [[Reverse alloc] init];
    _reverseController = [[ReverseController alloc] initWithNibName:@"ReverseController" bundle:nil];
    [_reverseContentView addSubview:[_reverseController view]];
    [self centerize:[_reverseController view]];
    [_reverseController setReverse:_reverse];
    
    _freezer = [[Freezer alloc] init];
    
    _viewer = [[Viewer alloc] init];
    [_waveView setViewer: _viewer];
    
    _refrain = [[Refrain alloc] init];
    _refrainController = [[RefrainController alloc] initWithNibName:@"RefrainView" bundle:nil];
    [_refrainContentView addSubview:[_refrainController view]];
    [self centerize:[_refrainController view]];
    [_refrainController setRefrain:_refrain];
    
    _crasher = [[BitCrasher alloc] init];
    _crasherController = [[BitCrasherController alloc] initWithNibName:@"BitCrasherController" bundle:nil];
    [_crasherContentView addSubview:[_crasherController view]];
    [_crasherController setBitCrasher:_crasher];
    
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
    [self centerize:[_randomController view]];
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

    
//    _convolutionReverb = [[ConvolutionReverb alloc] init];
//    _convolutionReverbController = [[ConvolutionReverbController alloc]
//                         initWithNibName:@"ConvolutionReverbController" bundle:nil];
//    [_convolutionReverbContentView addSubview:[_convolutionReverbController view]];
//    [self centerize:[_convolutionReverbController view]];
//    [_convolutionReverbController setConvolutionReverb:_convolutionReverb];
    

    _djFilter = [[DJFilter alloc] init];
    _djFilterController = [[DJFilterController alloc]
                           initWithNibName:@"DJFilterController" bundle:nil];
    [_djFilterContentView addSubview:[_djFilterController view]];
    [self centerize:[_djFilterController view]];
    [_djFilterController setDJFilter:_djFilter];
    
    [self startBonjour];
    
    _ae = [[AudioEngine alloc] init];
    if ([_ae initialize]){
        NSLog(@"AudioEngine all OK");
    }
    [_ae setRenderDelegate:(id<AudioEngineDelegate>)self];
    
    [_ae changeSystemOutputDeviceToBGM];
    usleep(1000*500);
    [_ae startOutput];
    usleep(1000*500);
    [_ae startInput];


    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(onGlobalTimer:) userInfo:nil repeats:YES];

    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
    //wake up
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(didWakenUp:) name:NSWorkspaceDidWakeNotification object:nil];
    
    
}

-(void)terminate{
    [_ae stopOutput];
    [_ae stopInput];
    [_ae restoreSystemOutputDevice];
}

-(void)turnTableSpeedRateChanged{
    _speedRate = [_turnTable speedRate];
    if (_speedRate == 1.0){
        [_ring follow];
        [_faderIn startFadeIn];
        return;
    }
}

-(void)centerize:(NSView *)view{
    NSView *superView = view.superview;
    NSPoint origin = NSMakePoint(
        (superView.frame.size.width - view.frame.size.width)/2,
        (superView.frame.size.height - view.frame.size.height)/2);
    [view setFrameOrigin:origin];
    
    [view setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin];
    
}


- (OSStatus) inCallback:(AudioUnitRenderActionFlags *)ioActionFlags inTimeStamp:(const AudioTimeStamp *) inTimeStamp inBusNumber:(UInt32) inBusNumber inNumberFrames:(UInt32)inNumberFrames ioData:(AudioBufferList *)ioData{
    

    static BOOL printNumFrames = NO;
    if (!printNumFrames){
        NSLog(@"inCallback NumFrames = %d", inNumberFrames);
        printNumFrames = YES;
    }
    
    AudioBufferList *bufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList) +  sizeof(AudioBuffer)); // for 2 buffers for left and right
    
    float *leftPrt = [_ring writePtrLeft];
    float *rightPtr = [_ring writePtrRight];
    
    bufferList->mNumberBuffers = 2;
    bufferList->mBuffers[0].mDataByteSize = 32*inNumberFrames;
    bufferList->mBuffers[0].mNumberChannels = 1;
    bufferList->mBuffers[0].mData = leftPrt;
    bufferList->mBuffers[1].mDataByteSize = 32*inNumberFrames;
    bufferList->mBuffers[1].mNumberChannels = 1;
    bufferList->mBuffers[1].mData = rightPtr;
    
    
    OSStatus ret = [_ae readFromInput:ioActionFlags inTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames ioData:bufferList];
    
    free(bufferList);
    
    if ([_ae isRecording]){
        [_ring advanceWritePtrSample:inNumberFrames];
    }
    
    return ret;
    
}

- (OSStatus) outCallback:(AudioUnitRenderActionFlags *)ioActionFlags inTimeStamp:(const AudioTimeStamp *) inTimeStamp inBusNumber:(UInt32) inBusNumber inNumberFrames:(UInt32)inNumberFrames ioData:(AudioBufferList *)ioData{
    
    static BOOL printedNumFrames = NO;
    if (!printedNumFrames){
        NSLog(@"outCallback NumFrames = %d", inNumberFrames);
        printedNumFrames = YES;
    }
    
    
    if (![_ae isPlaying]){
        UInt32 sampleNum = inNumberFrames;
        float *pLeft = (float *)ioData->mBuffers[0].mData;
        float *pRight = (float *)ioData->mBuffers[1].mData;
        bzero(pLeft,sizeof(float)*sampleNum );
        bzero(pRight,sizeof(float)*sampleNum );
        return noErr;
    }
    
    if ([_ring isShortage]){
        UInt32 sampleNum = inNumberFrames;
        float *pLeft = (float *)ioData->mBuffers[0].mData;
        float *pRight = (float *)ioData->mBuffers[1].mData;
        bzero(pLeft,sizeof(float)*sampleNum );
        bzero(pRight,sizeof(float)*sampleNum );
        NSLog(@"shortage in out thread");
        return noErr;
    }

    
    if (![_ring dryPtrLeft] || ![_ring dryPtrRight]){
         //not enough buffer
        NSLog(@"no enogh buffer on dry");
        UInt32 sampleNum = inNumberFrames;
        float *pLeft = (float *)ioData->mBuffers[0].mData;
        float *pRight = (float *)ioData->mBuffers[1].mData;
        bzero(pLeft, sizeof(float)*sampleNum );
        bzero(pRight, sizeof(float)*sampleNum );
        return noErr;
     }
    
    //beat tracker
//    [_beatTracker processLeft:(float*)ioData->mBuffers[0].mData
//                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    if(_speedRate == 1.0){

        float *dstL = (float *)ioData->mBuffers[0].mData;
        float *dstR = (float *)ioData->mBuffers[1].mData;
        
        memcpy(dstL,
               [_ring dryPtrLeft], sizeof(float) * inNumberFrames);
        memcpy(dstR,
               [_ring dryPtrRight], sizeof(float) * inNumberFrames);
        [_ring advanceDryPtrSample:inNumberFrames];
        [_ring advanceReadPtrSample:inNumberFrames];
        
        [_faderIn processLeft:dstL right:dstR samples:inNumberFrames];
        
    }else{
        
        //dry
        {
            float *pSrcLeft = [_ring dryPtrLeft];
            float *pSrcRight = [_ring dryPtrRight];
            float *pDstLeft = (float *)ioData->mBuffers[0].mData;
            float *pDstRight = (float *)ioData->mBuffers[1].mData;
            
            for(int i = 0; i < inNumberFrames; i++){
                pDstLeft[i]  = pSrcLeft[i] * _dryVolume;
                pDstRight[i] = pSrcRight[i] * _dryVolume;
            }
            [_ring advanceDryPtrSample:inNumberFrames];
        }
        
        //wet
        {
            SInt32 consumed = 0;
            [self convertAtRateFromLeft:[_ring readPtrLeft] right:[_ring readPtrRight] ToSamples:inNumberFrames
                                   rate:_speedRate consumedFrames:&consumed];

            float *pDstLeft = (float *)ioData->mBuffers[0].mData;
            float *pDstRight = (float *)ioData->mBuffers[1].mData;
            
            for(int i = 0; i < inNumberFrames; i++){
                pDstLeft[i] += _tempLeftPtr[i] * _wetVolume;
                pDstRight[i] += _tempRightPtr[i] * _wetVolume;
            }

            [_ring advanceReadPtrSample:consumed];
            
            [_faderIn processLeft:pDstLeft right:pDstRight samples:inNumberFrames];
        }
    }
    
    
    //looper
    [_looper processLeft:(float*)ioData->mBuffers[0].mData
                         right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //trill reverse
    [_trillReverse processLeft:(float*)ioData->mBuffers[0].mData
                         right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //bender
    [_bender processLeft:(float*)ioData->mBuffers[0].mData
                         right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
  
    //reverse
    [_reverse processLeft:(float*)ioData->mBuffers[0].mData
                         right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    
    //Freezer
    [_freezer processLeft:(float*)ioData->mBuffers[0].mData
                    right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];

    
    
    //refrain
    [_refrain processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    
    //bit crasher
    [_crasher processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
  
    
    //tape reverse
    [_tapeReverse processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //quick cue
    [_quickCue processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //flanger
    [_flanger processLeft:(float*)ioData->mBuffers[0].mData
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
    
    //DJ filter
    [_djFilter processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //Simple Reverb
    [_simpleReverb processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];

    //Convolution Reverb
//    [_convolutionReverb processLeft:(float*)ioData->mBuffers[0].mData
//                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    
    //viewer
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


- (IBAction)dryVolumeChanged:(id)sender {
    _dryVolume = [_sliderDryVolume floatValue];
}

- (IBAction)wetVolumeChanged:(id)sender {
    _wetVolume = [_sliderWetVolume floatValue];
}

- (IBAction)looperMarkStart:(id)sender {
    [_looper markStart];
}

- (IBAction)looperMarkEnd:(id)sender {
    [_looper markEnd];
}

- (IBAction)looperExit:(id)sender {
    [_looper exit];
}

- (IBAction)looperDoHalf:(id)sender {
    [_looper doHalf];
}

- (IBAction)looperDoQuater:(id)sender {
    [_looper doQuater];
}

- (IBAction)looperDoDivide8:(id)sender {
    [_looper divide8];
}

- (IBAction)_trillReverseChange:(id)sender {
    [_trillReverse setActive:([_chkTrillReverse state] == NSControlStateValueOn)];
}

- (IBAction)_benderBounceChanged:(id)sender {
    [_bender setBounce:(_chkBenderBounce.state == NSControlStateValueOn)];
}

- (IBAction)_benderRateChanged:(id)sender {
    [_bender setRate:[_sliderBenderRate floatValue]];
    if([[NSApplication sharedApplication] currentEvent].type == NSEventTypeLeftMouseUp){
        NSLog(@"bounce!");
        //[_sliderBenderRate setFloatValue:1.0];
        if(![_bender bounce]){
            [_bender resetRate];
            [_sliderBenderRate setFloatValue:1.0];
        }else{
            [self startBounce];
        }
    }
}

-(void)startBounce{
    _benderBounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(onBounceTimer:) userInfo:nil repeats:YES];
    
}

-(void)onBounceTimer:(NSTimer *)timer{
    
    if ([_bender isCatchingUp]){
        [_benderBounceTimer invalidate];
        [_sliderBenderRate setFloatValue:1.0];
        [_bender resetRate];
        return;
    }

    float rate = _sliderBenderRate.floatValue;
    rate += 0.1;
    if (rate >= 3.0){
        rate = 3.0;
    }
    [_sliderBenderRate setFloatValue:rate];
    [_bender setRate:rate];
    
}

- (IBAction)freezeChanged:(id)sender {
    [_freezer setActive:(_chkFreeze.state == NSControlStateValueOn)];
}


- (IBAction)freezeGrainsizeChanged:(id)sender {
    [_freezer setGrainSize:[_sliderGrainSize intValue]];
}

- (IBAction)monitorEnableChanged:(id)sender {
    if ([_chkWaveViewEnabled state] == NSControlStateValueOn){
        [_viewer setEnabled:YES];
    }else{
        [_viewer setEnabled:NO];
    }
}

-(void)onGlobalTimer:(NSTimer *)timer{
    if([_mainViewController isUpKeyPressed]){
        _wetVolume += 0.002;
        if (_wetVolume > 1.0f){
            _wetVolume = 1.0;
        }
        [_sliderWetVolume setFloatValue:_wetVolume];
        return;
    }
    
    if([_mainViewController isDownKeyPressed]){
        _wetVolume -= 0.002;
        if (_wetVolume < 0.0f){
            _wetVolume = 0.0;
        }
        [_sliderWetVolume setFloatValue:_wetVolume];
        return;
    }
}


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
            _speedRate = f;
            if (_speedRate == 1.0){
                [_ring follow];
            }
        }
    }else if ([addressPattern isEqualToString:@"/turntable/wet"]){
        if ([arg1 isKindOfClass:[NSNumber class]]){
            NSNumber *number = (NSNumber *)arg1;
            self.wetVolume = [number floatValue];
        }
    }else if ([addressPattern isEqualToString:@"/turntable/dry"]){
        if ([arg1 isKindOfClass:[NSNumber class]]){
            NSNumber *number = (NSNumber *)arg1;
            self.dryVolume = [number floatValue];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"dryVolume"]) {
        [_sliderDryVolume setFloatValue:self.dryVolume];
    }else if ([keyPath isEqual:@"wetVolume"]){
        [_sliderWetVolume setFloatValue:self.wetVolume];
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


@end
