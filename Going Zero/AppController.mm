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
    
    
    _looper = [[Looper alloc] init];
    
    _trillReverse = [[TrillReverse alloc] init];
    _bender = [[Bender alloc] init];
    
    _reverse = [[Reverse alloc] init];
    _reverseController = [[ReverseController alloc] initWithNibName:@"ReverseController" bundle:nil];
    [_reverseContentView addSubview:[_reverseController view]];
    [_reverseController setReverse:_reverse];
    
    
    _freezer = [[Freezer alloc] init];
    
    
    _viewer = [[Viewer alloc] init];
    [_waveView setRingBuffer:[_viewer ring]];
    
    _sampler = [[Sampler alloc] init];
    
    _djViewController = [[DJViewController alloc] initWithNibName:@"DJFilterView" bundle:nil];
    [_djContentView addSubview:[_djViewController view]];
    
    
    _refrain = [[Refrain alloc] init];
    _refrainController = [[RefrainController alloc] initWithNibName:@"RefrainView" bundle:nil];
    [_refrainContentView addSubview:[_refrainController view]];
    [_refrainController setRefrain:_refrain];
    
    _vocalRefrain = [[VocalRefrain alloc] init];
    _vocalRefrainController = [[VocalRefrainController alloc] initWithNibName:@"VocalRefrainController" bundle:nil];
    [_vocalRefrainContentView addSubview:[_vocalRefrainController view]];
    [_vocalRefrainController setVocalRefrain:_vocalRefrain];
    
    _crasher = [[BitCrasher alloc] init];
    _crasherController = [[BitCrasherController alloc] initWithNibName:@"BitCrasherController" bundle:nil];
    [_crasherContentView addSubview:[_crasherController view]];
    [_crasherController setBitCrasher:_crasher];
    
    
    _shooter = [[Shooter alloc] init];
    _shooterController = [[ShooterController alloc]
                          initWithNibName:@"ShooterController" bundle:nil];
    [_shooterContentView addSubview:[_shooterController view]];
    [_shooterController setShooter:_shooter];
    
    
    _tapeReverse = [[TapeReverse alloc] init];
    _tapeReverseController = [[TapeReverseController alloc] initWithNibName:@"TapeReverseController" bundle: nil];
    [_tapeReverseContentView addSubview:[_tapeReverseController view]];
    [_tapeReverseController setTapeReverse:_tapeReverse];
    
    _quickCue = [[QuickCue alloc] init];
    _quickCueController = [[QuickCueController alloc] initWithNibName:@"QuickCueController" bundle:nil];
    [_quickCueContentView addSubview:[_quickCueController view]];
    [_quickCueController setQuickCue:_quickCue];
    
    _ae = [[AudioEngine alloc] init];
    if ([_ae initialize]){
        NSLog(@"AudioEngine all OK");
    }
    [_ae setRenderDelegate:(id<AudioEngineDelegate>)self];
    [_ae startInput];
    [_ae startOutput];
    [_ae changeSystemOutputDeviceToBGM];
    
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
    }
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
//        NSLog(@"shortage in out thread");
        return noErr;
    }

    
    if (![_ring dryPtrLeft] || ![_ring dryPtrRight]){
         //not enough buffer
         UInt32 sampleNum = inNumberFrames;
         float *pLeft = (float *)ioData->mBuffers[0].mData;
         float *pRight = (float *)ioData->mBuffers[1].mData;
         bzero(pLeft, sizeof(float)*sampleNum );
         bzero(pRight, sizeof(float)*sampleNum );
         return noErr;
     }
    
    if(_speedRate == 1.0){

        memcpy(ioData->mBuffers[0].mData,
               [_ring dryPtrLeft], sizeof(float) * inNumberFrames);
        memcpy(ioData->mBuffers[1].mData,
               [_ring dryPtrRight], sizeof(float) * inNumberFrames);
        [_ring advanceDryPtrSample:inNumberFrames];
        [_ring advanceReadPtrSample:inNumberFrames];
        
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
    
    //sampler
    [_sampler processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    
    //refrain
    [_refrain processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
 
    //vocal refrain
    [_vocalRefrain processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    
    //bit crasher
    [_crasher processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
  
    
    //shooter
    [_shooter processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //tape reverse
    [_tapeReverse processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
    //quick cue
    [_quickCue processLeft:(float*)ioData->mBuffers[0].mData
                        right:(float*)ioData->mBuffers[1].mData samples:inNumberFrames];
    
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

//- (IBAction)_benderChange:(id)sender {
//    NSLog(@"active : %d", [_chkBender state] == NSControlStateValueOn);
//    [_bender setActive:([_chkBender state] == NSControlStateValueOn)];
//    
//
//}

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


- (IBAction)samplerClicked:(id)sender {
    [_sampler gotoNextState];
    UInt32 state = [_sampler state];
    switch (state){
        case SAMPLER_STATE_READYRECORD:
            [_btnSampler setTitle:@"O"];
            break;
        case SAMPLER_STATE_RECORDING:
            [_btnSampler setTitle:@"|"];
            break;
        case SAMPLER_STATE_READYPLAY:
            [_btnSampler setTitle:@">"];
            break;
        case SAMPLER_STATE_PLAYING:
            [_btnSampler setTitle:@"-"];
            break;
        default:
            break;
    }
}

- (IBAction)samplerClearClicked:(id)sender {
    [_sampler clear];
    UInt32 state = [_sampler state];
    switch (state){
        case SAMPLER_STATE_READYRECORD:
            [_btnSampler setTitle:@"O"];
            break;
        case SAMPLER_STATE_RECORDING:
            [_btnSampler setTitle:@"|"];
            break;
        case SAMPLER_STATE_READYPLAY:
            [_btnSampler setTitle:@">"];
            break;
        case SAMPLER_STATE_PLAYING:
            [_btnSampler setTitle:@"-"];
            break;
        default:
            break;
    }
    
    
}

- (IBAction)samplerPanChanged:(id)sender {
    [_sampler setPan:[_sliderSamplerPan floatValue]];

}


@end
