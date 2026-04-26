//
//  TurnTableController.m
//  Going Zero
//
//  Created by yoshioka on 2024/01/24.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "TurnTableController.h"

// ---------------------------------------------------------------------------
// Turn-table / scratch processor with A/B switch
//
// Two complete scratch implementations coexist in this file:
//
//   Algorithm A: the original implementation. Linear interpolation,
//                integer-advance resampling, hard silence when |speed|==0,
//                and an extra fade-transition state (_isSpeedChangingA)
//                to hide the click when crossing zero.
//
//   Algorithm B: xwax-inspired. Cubic Hermite interpolation, double-precision
//                sub-sample playhead, per-sample one-pole smoothed speed and
//                wet gain, pitch-proportional volume (so zero speed is
//                naturally silent), plus a small DC blocker on the wet.
//
// The UI (checkbox _chkUseNewAlgorithm) picks one. The choice is latched
// into _activeAlgorithm at the instant a new scratch begins, then held
// until that scratch has fully ended (including the closing fade-in back
// to normal playback). Toggling the checkbox mid-scratch is ignored on
// purpose so that A/B comparisons are stable.
// ---------------------------------------------------------------------------

// --- Algorithm B tuning constants ------------------------------------------

// One-pole time constant for the audio-rate speed smoother (~3 ms @ 44.1 kHz).
// Long enough to merge 100 Hz UI ticks into a continuous pitch ramp, short
// enough that the user still feels the scratch tracking the mouse.
#define SPEED_SMOOTH_ALPHA     (1.0 / 128.0)

// One-pole time constant for the pitch-driven wet-gain smoother (~6 ms).
// Slightly slower than the speed smoother so micro-oscillations around
// zero speed don't re-open the gate instantly.
#define GAIN_SMOOTH_ALPHA      (1.0 / 256.0)

// DC blocker pole. 0.995 corresponds to a ~35 Hz high-pass at 44.1 kHz.
#define DC_BLOCKER_R           (0.995f)

// target_gain = min(|speed| * GAIN_SLOPE, 1.0). A slope of 4 means full
// wet volume is reached at |speed| = 0.25, and the record fades to
// silence linearly below that.
#define GAIN_SLOPE             (4.0)

// |speed| below which the record is considered "essentially stopped":
// target gain is clamped to 0 so the smoother coasts to true silence.
#define STOPPED_SPEED_EPSILON  (1.0e-4)

@interface TurnTableController ()
@end

@implementation TurnTableController

- (void)dealloc{
    [_tableStopTimer invalidate];
    _tableStopTimer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _ring = [[RingBuffer alloc] init];
    [_ring setMinOffset:0];
    
    [_turnTableView setDelegate:self];
    [_turnTableView setRingBuffer:_ring];
    [_turnTableView start];
    
    _wetVolume = 1.0;
    _dryVolume = 0.0;
    _speedRate = 1.0;
    
    // Default to B (the new algorithm). The checkbox defaults on; if
    // the xib initializes the button state to off, -viewDidLoad does
    // not observe that here, so sync from the outlet after the nib has
    // loaded.
    _selectedAlgorithm = TurnTableAlgorithmB;
    _activeAlgorithm   = TurnTableAlgorithmB;
    
    // Shared fade state
    _isScratchStarting = NO;
    _isScratchEnding   = NO;
    _isFadingOut       = NO;
    _isFadingIn        = NO;
    _fadeOutCounter    = 0;
    _fadeInCounter     = 0;
    
    // Algo A
    _isSpeedChangingA  = NO;
    _pendingSpeedRateA = 1.0;
    
    // Algo B
    _smoothedSpeedB    = 1.0;
    _subSamplePosB     = 0.0;
    _wetGainB          = 1.0;
    _dcInLB = _dcOutLB = 0.0f;
    _dcInRB = _dcOutRB = 0.0f;
    _isScratchingB     = NO;
    _tableStopTimer    = nil;
    _isTableStopping   = NO;
    _isTableStopped    = NO;
    
    // Pick up the checkbox's current state from the nib, if any.
    if (_chkUseNewAlgorithm != nil){
        _selectedAlgorithm = ([_chkUseNewAlgorithm state] == NSControlStateValueOn)
                                 ? TurnTableAlgorithmB
                                 : TurnTableAlgorithmA;
        _activeAlgorithm = _selectedAlgorithm;
    }
    [self updateTableStopButtonTitle];
}

// ---------------------------------------------------------------------------
// IBAction: A/B checkbox
//
// Writes _selectedAlgorithm on the UI thread. The change does NOT take
// effect while a scratch is in progress -- it is only sampled when a new
// scratch begins.
// ---------------------------------------------------------------------------
- (IBAction)useNewAlgorithmChanged:(id)sender {
    _selectedAlgorithm = ([_chkUseNewAlgorithm state] == NSControlStateValueOn)
                             ? TurnTableAlgorithmB
                             : TurnTableAlgorithmA;
}

// Helper: are we in pure-normal playback with no scratch or fade in flight?
// Only in that state is it safe to pick up a new algorithm choice from the
// checkbox.
-(BOOL)isFullyIdle{
    return (_speedRate == 1.0
            && !_isFadingOut
            && !_isFadingIn
            && !_isScratchStarting
            && !_isScratchEnding
            && !_isScratchingB);
}

- (IBAction)wetVolumeChanged:(id)sender {
    _wetVolume = [_sliderWetVolume floatValue];
}

- (IBAction)dryVolumeChanged:(id)sender {
    _dryVolume = [_sliderDryVolume floatValue];
}

- (void)updateTableStopButtonTitle{
    if (_btnTableStopStart == nil){
        return;
    }
    if (_isTableStopped || _isTableStopping){
        [_btnTableStopStart setTitle:@"Start"];
    }else{
        [_btnTableStopStart setTitle:@"Stop"];
    }
}

- (void)invalidateTableStopTimer{
    if (_tableStopTimer != nil){
        [_tableStopTimer invalidate];
        _tableStopTimer = nil;
    }
}

- (void)setExternalSpeedRate:(double)newSpeedRate{
    if (newSpeedRate == 1.0){
        _isTableStopping = NO;
    }
    _isTableStopped = NO;
    [self updateTableStopButtonTitle];
    [self turnTableSpeedRateChangedA:newSpeedRate];
    [self turnTableSpeedRateChangedB:newSpeedRate];
}

- (void)tableStopTimerTick:(NSTimer *)timer{
    (void)timer;
    if (!_isTableStopping){
        [self invalidateTableStopTimer];
        return;
    }
    if (fabs(_speedRate) < 0.01){
        [self setExternalSpeedRate:0.0];
        _isTableStopping = NO;
        _isTableStopped = YES;
        [self updateTableStopButtonTitle];
        [self invalidateTableStopTimer];
        return;
    }
    double nextSpeedRate = _speedRate;
    if (nextSpeedRate > 0.0){
        nextSpeedRate -= 0.02;
        if (nextSpeedRate < 0.0){
            nextSpeedRate = 0.0;
        }
    }else{
        nextSpeedRate += 0.02;
        if (nextSpeedRate > 0.0){
            nextSpeedRate = 0.0;
        }
    }
    [self setExternalSpeedRate:nextSpeedRate];
}

- (IBAction)tableStopClicked:(id)sender {
    (void)sender;
    if (_isTableStopping || _isTableStopped){
        [self invalidateTableStopTimer];
        _isTableStopping = NO;
        _isTableStopped = NO;
        [self setExternalSpeedRate:1.0];
        [_ring follow];
        [self updateTableStopButtonTitle];
        return;
    }
    _isTableStopping = YES;
    [self updateTableStopButtonTitle];
    [self invalidateTableStopTimer];
    _tableStopTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                        target:self
                                                      selector:@selector(tableStopTimerTick:)
                                                      userInfo:nil
                                                       repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_tableStopTimer forMode:NSRunLoopCommonModes];
}

// ---------------------------------------------------------------------------
// UI -> audio-thread glue
//
// Called from the TurnTableView timer at ~100 Hz whenever the user drags
// the record. At the first transition out of fully-idle, we latch the
// current algorithm selection; any algorithm toggles that arrive before
// this scratch has fully ended are ignored.
// ---------------------------------------------------------------------------
-(void)turnTableSpeedRateChanged{
    double newSpeedRate = [_turnTableView speedRate];
    
    // Algorithm latch: only sample _selectedAlgorithm when a brand-new
    // scratch is starting. Within a scratch (or its closing fade-in),
    // _activeAlgorithm stays fixed.
    BOOL startingNewScratch = ([self isFullyIdle] && newSpeedRate != 1.0);
    if (startingNewScratch){
        _activeAlgorithm = _selectedAlgorithm;
    }
    
    if (_activeAlgorithm == TurnTableAlgorithmA){
        [self turnTableSpeedRateChangedA:newSpeedRate];
    }else{
        [self turnTableSpeedRateChangedB:newSpeedRate];
    }
}

// ===========================================================================
//                           ALGORITHM A  (original)
// ===========================================================================
#pragma mark - Algorithm A

-(void)turnTableSpeedRateChangedA:(double)newSpeedRate{
    // Already in fade-out: queue the value for application after the fade.
    if (_isFadingOut){
        _pendingSpeedRateA = newSpeedRate;
        return;
    }
    
    // Scratch starting (normal -> scratch)
    if (_speedRate == 1.0 && newSpeedRate != 1.0){
        _isScratchStarting = YES;
        _isFadingOut       = YES;
        _fadeOutCounter    = FADE_SAMPLE_NUM;
        _pendingSpeedRateA = newSpeedRate;
        return;
    }
    
    // Scratch ending (scratch -> normal)
    if (_speedRate != 1.0 && newSpeedRate == 1.0){
        _isScratchEnding = YES;
        _isFadingOut     = YES;
        _fadeOutCounter  = FADE_SAMPLE_NUM;
        return;
    }
    
    // Speed change to/from zero during scratch (would otherwise pop)
    if (_speedRate != 1.0 && newSpeedRate != 1.0){
        if ((_speedRate == 0.0 && newSpeedRate != 0.0) ||
            (_speedRate != 0.0 && newSpeedRate == 0.0)){
            _isSpeedChangingA  = YES;
            _isFadingOut       = YES;
            _fadeOutCounter    = FADE_SAMPLE_NUM;
            _pendingSpeedRateA = newSpeedRate;
            return;
        }
    }
    
    _speedRate = newSpeedRate;
}

-(void)completeScratchEndingA{
    _speedRate       = 1.0;
    [_ring follow];
    _isFadingOut     = NO;
    _isFadingIn      = YES;
    _fadeInCounter   = 0;
    _isScratchEnding = NO;
}

-(void)completeScratchStartingA{
    _speedRate         = _pendingSpeedRateA;
    _isFadingOut       = NO;
    _isFadingIn        = YES;
    _fadeInCounter     = 0;
    _isScratchStarting = NO;
}

-(void)completeSpeedChangeA{
    _speedRate         = _pendingSpeedRateA;
    _isFadingOut       = NO;
    _isFadingIn        = YES;
    _fadeInCounter     = 0;
    _isSpeedChangingA  = NO;
}

// --- Algorithm A resampler (linear, integer-advance) ----------------------

static double linearInterporationA(int x0, double y0, int x1, double y1, double x){
    if (x0 == x1){
        return y0;
    }
    double rate = (x - x0) / (x1 - x0);
    return (1.0 - rate)*y0 + rate*y1;
}

-(void)convertAtRateA_FromLeft:(float *)srcL right:(float *)srcR
                      leftDest:(float *)dstL rightDest:(float *)dstR
                     ToSamples:(UInt32)inNumberFrames
                          rate:(double)rate
                consumedFrames:(SInt32 *)consumed{
    if (rate == 1.0){
        memcpy(dstL, srcL, inNumberFrames * sizeof(float));
        memcpy(dstR, srcR, inNumberFrames * sizeof(float));
        *consumed = inNumberFrames;
        return;
    }
    *consumed = 0;
    for (int targetSample = 0; targetSample < (int)inNumberFrames; targetSample++){
        int x0 = (int)floor(targetSample * rate);
        int x1 = (int)ceil (targetSample * rate);
        
        float y0_l = srcL[x0];
        float y1_l = srcL[x1];
        float y_l = (float)linearInterporationA(x0, y0_l, x1, y1_l, targetSample * rate);
        
        float y0_r = srcR[x0];
        float y1_r = srcR[x1];
        float y_r = (float)linearInterporationA(x0, y0_r, x1, y1_r, targetSample * rate);
        
        dstL[targetSample] = y_l;
        dstR[targetSample] = y_r;
        *consumed = x1;
    }
}

-(void)processScratchStateA:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    if (_speedRate == 0.0){
        for (UInt32 i = 0; i < numSamples; i++){
            float dryL = leftBuf[i] * _dryVolume;
            float dryR = rightBuf[i] * _dryVolume;
            leftBuf[i]  = dryL;
            rightBuf[i] = dryR;
        }
        if (_isFadingIn){
            _fadeInCounter = FADE_SAMPLE_NUM;
            _isFadingIn    = NO;
        }
        return;
    }
    
    SInt32 consumed = 0;
    [self convertAtRateA_FromLeft:[_ring readPtrLeft] right:[_ring readPtrRight]
                         leftDest:_tempLeftPtr rightDest:_tempRightPtr
                        ToSamples:numSamples
                             rate:_speedRate
                   consumedFrames:&consumed];
    
    for (UInt32 i = 0; i < numSamples; i++){
        float dryL = leftBuf[i] * _dryVolume;
        float dryR = rightBuf[i] * _dryVolume;
        float wetL = _tempLeftPtr[i] * _wetVolume;
        float wetR = _tempRightPtr[i] * _wetVolume;
        
        if (_isFadingIn){
            float r = _fadeInCounter / (float)FADE_SAMPLE_NUM;
            wetL *= r;
            wetR *= r;
            _fadeInCounter++;
            if (_fadeInCounter >= FADE_SAMPLE_NUM){
                _isFadingIn = NO;
            }
        }
        
        leftBuf[i]  = dryL + wetL;
        rightBuf[i] = dryR + wetR;
    }
    [_ring advanceReadPtrSample:consumed];
}

-(UInt32)processFadeOutForScratchStartA:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    UInt32 n = (numSamples < _fadeOutCounter) ? numSamples : _fadeOutCounter;
    [_ring advanceReadPtrSample:n];
    
    for (UInt32 i = 0; i < n; i++){
        float dryL = leftBuf[i] * _dryVolume;
        float dryR = rightBuf[i] * _dryVolume;
        float wetL = leftBuf[i] * _wetVolume;
        float wetR = rightBuf[i] * _wetVolume;
        
        float r = _fadeOutCounter / (float)FADE_SAMPLE_NUM;
        wetL *= r;
        wetR *= r;
        _fadeOutCounter--;
        
        leftBuf[i]  = dryL + wetL;
        rightBuf[i] = dryR + wetR;
        
        if (_fadeOutCounter == 0){
            [self completeScratchStartingA];
            return i + 1;
        }
    }
    return n;
}

-(UInt32)processFadeOutForSpeedChangeA:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    UInt32 n = (numSamples < _fadeOutCounter) ? numSamples : _fadeOutCounter;
    
    if (_speedRate == 0.0){
        for (UInt32 i = 0; i < n; i++){
            leftBuf[i]  = leftBuf[i]  * _dryVolume;
            rightBuf[i] = rightBuf[i] * _dryVolume;
            _fadeOutCounter--;
            if (_fadeOutCounter == 0){
                [self completeSpeedChangeA];
                return i + 1;
            }
        }
    }else{
        SInt32 consumed = 0;
        [self convertAtRateA_FromLeft:[_ring readPtrLeft] right:[_ring readPtrRight]
                             leftDest:_tempLeftPtr rightDest:_tempRightPtr
                            ToSamples:n
                                 rate:_speedRate
                       consumedFrames:&consumed];
        [_ring advanceReadPtrSample:consumed];
        
        for (UInt32 i = 0; i < n; i++){
            float dryL = leftBuf[i] * _dryVolume;
            float dryR = rightBuf[i] * _dryVolume;
            float wetL = _tempLeftPtr[i] * _wetVolume;
            float wetR = _tempRightPtr[i] * _wetVolume;
            
            float r = _fadeOutCounter / (float)FADE_SAMPLE_NUM;
            wetL *= r;
            wetR *= r;
            _fadeOutCounter--;
            
            leftBuf[i]  = dryL + wetL;
            rightBuf[i] = dryR + wetR;
            
            if (_fadeOutCounter == 0){
                [self completeSpeedChangeA];
                return i + 1;
            }
        }
    }
    return n;
}

-(UInt32)processFadeOutForScratchEndA:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    UInt32 n = (numSamples < _fadeOutCounter) ? numSamples : _fadeOutCounter;
    
    if (_speedRate == 0.0){
        for (UInt32 i = 0; i < n; i++){
            leftBuf[i]  = leftBuf[i]  * _dryVolume;
            rightBuf[i] = rightBuf[i] * _dryVolume;
            _fadeOutCounter--;
            if (_fadeOutCounter == 0){
                [self completeScratchEndingA];
                return i + 1;
            }
        }
        return n;
    }
    
    SInt32 consumed = 0;
    [self convertAtRateA_FromLeft:[_ring readPtrLeft] right:[_ring readPtrRight]
                         leftDest:_tempLeftPtr rightDest:_tempRightPtr
                        ToSamples:n
                             rate:_speedRate
                   consumedFrames:&consumed];
    [_ring advanceReadPtrSample:consumed];
    
    for (UInt32 i = 0; i < n; i++){
        float dryL = leftBuf[i] * _dryVolume;
        float dryR = rightBuf[i] * _dryVolume;
        float wetL = _tempLeftPtr[i] * _wetVolume;
        float wetR = _tempRightPtr[i] * _wetVolume;
        
        float r = _fadeOutCounter / (float)FADE_SAMPLE_NUM;
        wetL *= r;
        wetR *= r;
        _fadeOutCounter--;
        
        leftBuf[i]  = dryL + wetL;
        rightBuf[i] = dryR + wetR;
        
        if (_fadeOutCounter == 0){
            [self completeScratchEndingA];
            return i + 1;
        }
    }
    return n;
}

-(void)processLeftA:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    if (_isFadingOut){
        UInt32 processed = 0;
        if (_isScratchStarting){
            processed = [self processFadeOutForScratchStartA:leftBuf right:rightBuf samples:numSamples];
            if (processed < numSamples){
                [self processScratchStateA:&leftBuf[processed]
                                     right:&rightBuf[processed]
                                   samples:numSamples - processed];
            }
        }else if (_isScratchEnding){
            processed = [self processFadeOutForScratchEndA:leftBuf right:rightBuf samples:numSamples];
            if (processed < numSamples){
                [self processNormalState:&leftBuf[processed]
                                   right:&rightBuf[processed]
                                 samples:numSamples - processed];
            }
        }else if (_isSpeedChangingA){
            processed = [self processFadeOutForSpeedChangeA:leftBuf right:rightBuf samples:numSamples];
            if (processed < numSamples){
                [self processScratchStateA:&leftBuf[processed]
                                     right:&rightBuf[processed]
                                   samples:numSamples - processed];
            }
        }
        return;
    }
    
    if (_speedRate == 1.0){
        [self processNormalState:leftBuf right:rightBuf samples:numSamples];
    }else{
        [self processScratchStateA:leftBuf right:rightBuf samples:numSamples];
    }
}

// ===========================================================================
//                   ALGORITHM B  (xwax-inspired, smoothed)
// ===========================================================================
#pragma mark - Algorithm B

-(void)turnTableSpeedRateChangedB:(double)newSpeedRate{
    _speedRate = newSpeedRate;
    
    // Case A: user grabbed the record mid-release-fade. Reverse the fade.
    if (_isScratchEnding && newSpeedRate != 1.0){
        _isScratchEnding   = NO;
        _isScratchStarting = YES;
        _isFadingOut       = YES;
        _fadeOutCounter    = FADE_SAMPLE_NUM;
        return;
    }
    
    // Case B: user released the record mid-grab-fade. Reverse the fade.
    if (_isScratchStarting && newSpeedRate == 1.0){
        _isScratchStarting = NO;
        _isScratchEnding   = YES;
        _isFadingOut       = YES;
        _fadeOutCounter    = FADE_SAMPLE_NUM;
        return;
    }
    
    // Case C: plain scratch starting.
    if (!_isScratchingB && !_isFadingOut && newSpeedRate != 1.0){
        _isScratchStarting = YES;
        _isFadingOut       = YES;
        _fadeOutCounter    = FADE_SAMPLE_NUM;
        return;
    }
    
    // Case D: plain scratch ending.
    if (_isScratchingB && !_isFadingOut && newSpeedRate == 1.0){
        _isScratchEnding = YES;
        _isFadingOut     = YES;
        _fadeOutCounter  = FADE_SAMPLE_NUM;
        return;
    }
    
    // Case E: mid-scratch speed update. The audio-thread smoother picks
    // up the new target next block. No click-hiding fade needed because
    // crossing zero is handled by the pitch-proportional wet gain.
}

// Cubic Hermite (Catmull-Rom-style) interpolation, ported from xwax player.c.
static inline float cubicInterpolateB(float y0, float y1, float y2, float y3, double mu){
    double mu2 = mu * mu;
    double a0 = (double)y3 - (double)y2 - (double)y0 + (double)y1;
    double a1 = (double)y0 - (double)y1 - a0;
    double a2 = (double)y2 - (double)y0;
    double a3 = (double)y1;
    return (float)((mu * mu2 * a0) + (mu2 * a1) + (mu * a2) + a3);
}

// Walks a double-precision read head across the ring buffer, linearly
// ramping the speed from startSpeed to endSpeed across the output block.
-(void)resampleB_FromLeft:(float *)baseL right:(float *)baseR
                toDstLeft:(float *)dstL dstRight:(float *)dstR
                  samples:(UInt32)numSamples
               startSpeed:(double)startSpeed
                 endSpeed:(double)endSpeed
                   subPos:(double *)subPos
                 consumed:(SInt32 *)consumed{
    double pos    = *subPos;
    double speed  = startSpeed;
    double dSpeed = (endSpeed - startSpeed) / (double)numSamples;
    SInt32 integerBase = 0;
    
    for (UInt32 i = 0; i < numSamples; i++){
        while (pos >= 1.0){ pos -= 1.0; integerBase += 1; }
        while (pos <  0.0){ pos += 1.0; integerBase -= 1; }
        
        float l0 = baseL[integerBase - 1];
        float l1 = baseL[integerBase    ];
        float l2 = baseL[integerBase + 1];
        float l3 = baseL[integerBase + 2];
        
        float r0 = baseR[integerBase - 1];
        float r1 = baseR[integerBase    ];
        float r2 = baseR[integerBase + 1];
        float r3 = baseR[integerBase + 2];
        
        dstL[i] = cubicInterpolateB(l0, l1, l2, l3, pos);
        dstR[i] = cubicInterpolateB(r0, r1, r2, r3, pos);
        
        pos   += speed;
        speed += dSpeed;
    }
    
    while (pos >= 1.0){ pos -= 1.0; integerBase += 1; }
    while (pos <  0.0){ pos += 1.0; integerBase -= 1; }
    
    *subPos   = pos;
    *consumed = integerBase;
}

-(void)processScratchBlockB:(float *)leftBuf right:(float *)rightBuf
                    samples:(UInt32)numSamples
             applyExtraFade:(BOOL)applyExtraFade{
    if (numSamples == 0) return;
    
    // Unroll the one-pole smoothers into (start, end) values across the
    // block. The resampler interpolates speed linearly, and we ramp the
    // gain linearly inside the mix loop.
    double targetSpeed = _speedRate;
    double speedStart  = _smoothedSpeedB;
    double speedEnd    = speedStart;
    for (UInt32 i = 0; i < numSamples; i++){
        speedEnd += (targetSpeed - speedEnd) * SPEED_SMOOTH_ALPHA;
    }
    
    double absMean    = 0.5 * (fabs(speedStart) + fabs(speedEnd));
    double targetGain = absMean * GAIN_SLOPE;
    if (targetGain > 1.0)                 targetGain = 1.0;
    if (absMean < STOPPED_SPEED_EPSILON)  targetGain = 0.0;
    
    double gainStart = _wetGainB;
    double gainEnd   = gainStart;
    for (UInt32 i = 0; i < numSamples; i++){
        gainEnd += (targetGain - gainEnd) * GAIN_SMOOTH_ALPHA;
    }
    
    float *baseL = [_ring readPtrLeft];
    float *baseR = [_ring readPtrRight];
    
    SInt32 consumed = 0;
    if (baseL != NULL && baseR != NULL){
        [self resampleB_FromLeft:baseL right:baseR
                       toDstLeft:_tempLeftPtr dstRight:_tempRightPtr
                         samples:numSamples
                      startSpeed:speedStart
                        endSpeed:speedEnd
                          subPos:&_subSamplePosB
                        consumed:&consumed];
    }else{
        memset(_tempLeftPtr,  0, sizeof(float) * numSamples);
        memset(_tempRightPtr, 0, sizeof(float) * numSamples);
    }
    
    double gain  = gainStart;
    double dGain = (gainEnd - gainStart) / (double)numSamples;
    
    float dcInL  = _dcInLB;
    float dcOutL = _dcOutLB;
    float dcInR  = _dcInRB;
    float dcOutR = _dcOutRB;
    
    double extraFade = applyExtraFade ? (_fadeOutCounter / (double)FADE_SAMPLE_NUM) : 1.0;
    double extraFadeEnd;
    if (applyExtraFade){
        SInt32 counterEnd = (SInt32)_fadeOutCounter - (SInt32)numSamples;
        if (counterEnd < 0) counterEnd = 0;
        extraFadeEnd = counterEnd / (double)FADE_SAMPLE_NUM;
    }else{
        extraFadeEnd = 1.0;
    }
    double dExtraFade = (extraFadeEnd - extraFade) / (double)numSamples;
    
    for (UInt32 i = 0; i < numSamples; i++){
        float inL = _tempLeftPtr[i];
        float inR = _tempRightPtr[i];
        
        // y[n] = x[n] - x[n-1] + R * y[n-1]  -- leaky differentiator
        float outL = inL - dcInL + DC_BLOCKER_R * dcOutL;
        float outR = inR - dcInR + DC_BLOCKER_R * dcOutR;
        dcInL = inL;  dcOutL = outL;
        dcInR = inR;  dcOutR = outR;
        
        float dryL = leftBuf[i]  * _dryVolume;
        float dryR = rightBuf[i] * _dryVolume;
        
        float wetL = outL * _wetVolume * (float)(gain * extraFade);
        float wetR = outR * _wetVolume * (float)(gain * extraFade);
        
        if (_isFadingIn){
            float r = _fadeInCounter / (float)FADE_SAMPLE_NUM;
            wetL *= r;
            wetR *= r;
            _fadeInCounter++;
            if (_fadeInCounter >= FADE_SAMPLE_NUM){
                _isFadingIn = NO;
            }
        }
        
        leftBuf[i]  = dryL + wetL;
        rightBuf[i] = dryR + wetR;
        
        gain      += dGain;
        extraFade += dExtraFade;
    }
    
    _dcInLB = dcInL;  _dcOutLB = dcOutL;
    _dcInRB = dcInR;  _dcOutRB = dcOutR;
    
    _smoothedSpeedB = speedEnd;
    _wetGainB       = gainEnd;
    [_ring advanceReadPtrSample:consumed];
    
    if (applyExtraFade){
        if (_fadeOutCounter >= numSamples){
            _fadeOutCounter -= numSamples;
        }else{
            _fadeOutCounter = 0;
        }
    }
}

-(void)processScratchStateB:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    [self processScratchBlockB:leftBuf right:rightBuf samples:numSamples applyExtraFade:NO];
}

-(UInt32)processFadeOutForScratchStartB:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    UInt32 n = (numSamples < _fadeOutCounter) ? numSamples : _fadeOutCounter;
    
    [_ring advanceReadPtrSample:n];
    
    for (UInt32 i = 0; i < n; i++){
        float dryL = leftBuf[i] * _dryVolume;
        float dryR = rightBuf[i] * _dryVolume;
        float wetL = leftBuf[i] * _wetVolume;
        float wetR = rightBuf[i] * _wetVolume;
        
        float r = _fadeOutCounter / (float)FADE_SAMPLE_NUM;
        wetL *= r;
        wetR *= r;
        _fadeOutCounter--;
        
        leftBuf[i]  = dryL + wetL;
        rightBuf[i] = dryR + wetR;
        
        if (_fadeOutCounter == 0){
            [_ring follow];
            _subSamplePosB     = 0.0;
            _smoothedSpeedB    = 1.0;
            _wetGainB          = 1.0;
            _isScratchingB     = YES;
            _isFadingOut       = NO;
            _isFadingIn        = YES;
            _fadeInCounter     = 0;
            _isScratchStarting = NO;
            return i + 1;
        }
    }
    return n;
}

-(UInt32)processFadeOutForScratchEndB:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    UInt32 n = (numSamples < _fadeOutCounter) ? numSamples : _fadeOutCounter;
    
    [self processScratchBlockB:leftBuf right:rightBuf samples:n applyExtraFade:YES];
    
    if (_fadeOutCounter == 0){
        [_ring follow];
        _subSamplePosB     = 0.0;
        _smoothedSpeedB    = 1.0;
        _wetGainB          = 0.0;
        _isScratchingB     = NO;
        _isFadingOut       = NO;
        _isFadingIn        = YES;
        _fadeInCounter     = 0;
        _isScratchEnding   = NO;
    }
    return n;
}

-(void)processLeftB:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    if (_isFadingOut){
        UInt32 processed = 0;
        if (_isScratchStarting){
            processed = [self processFadeOutForScratchStartB:leftBuf right:rightBuf samples:numSamples];
            if (processed < numSamples){
                [self processScratchStateB:&leftBuf[processed]
                                     right:&rightBuf[processed]
                                   samples:numSamples - processed];
            }
        }else if (_isScratchEnding){
            processed = [self processFadeOutForScratchEndB:leftBuf right:rightBuf samples:numSamples];
            if (!_isFadingOut && processed < numSamples){
                [self processNormalState:&leftBuf[processed]
                                   right:&rightBuf[processed]
                                 samples:numSamples - processed];
            }
        }
        return;
    }
    
    if (_isScratchingB){
        [self processScratchStateB:leftBuf right:rightBuf samples:numSamples];
    }else{
        [self processNormalState:leftBuf right:rightBuf samples:numSamples];
    }
}

// ===========================================================================
//                         Shared  (normal / dispatcher)
// ===========================================================================
#pragma mark - Shared

// Normal-playback renderer used by both algorithms. Pass-through with an
// optional fade-in on the wet branch.
-(void)processNormalState:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    [_ring advanceReadPtrSample:numSamples];
    
    for (UInt32 i = 0; i < numSamples; i++){
        float dryL = leftBuf[i] * _dryVolume;
        float dryR = rightBuf[i] * _dryVolume;
        float wetL = leftBuf[i] * _wetVolume;
        float wetR = rightBuf[i] * _wetVolume;
        
        if (_isFadingIn){
            float r = _fadeInCounter / (float)FADE_SAMPLE_NUM;
            wetL *= r;
            wetR *= r;
            _fadeInCounter++;
            if (_fadeInCounter >= FADE_SAMPLE_NUM){
                _isFadingIn = NO;
            }
        }
        
        leftBuf[i]  = dryL + wetL;
        rightBuf[i] = dryR + wetR;
    }
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    // 1. Always write the input to the ring -- both algorithms need a
    //    recent history to read from during scratching.
    {
        float *dstL = [_ring writePtrLeft];
        float *dstR = [_ring writePtrRight];
        memcpy(dstL, leftBuf,  numSamples * sizeof(float));
        memcpy(dstR, rightBuf, numSamples * sizeof(float));
        [_ring advanceWritePtrSample:numSamples];
    }
    
    // 2. Dispatch to the currently-active algorithm. _activeAlgorithm is
    //    latched at scratch start and held until the scratch has fully
    //    ended, so A/B comparisons are stable even if the user toggles
    //    the checkbox mid-scratch.
    if (_activeAlgorithm == TurnTableAlgorithmA){
        [self processLeftA:leftBuf right:rightBuf samples:numSamples];
    }else{
        [self processLeftB:leftBuf right:rightBuf samples:numSamples];
    }
}

@end
