//
//  TurnTableController.m
//  Going Zero
//
//  Created by yoshioka on 2024/01/24.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "TurnTableController.h"

// ---------------------------------------------------------------------------
// Turn-table / scratch processor
//
// Design notes (see also the accompanying PR description):
//
// The previous implementation had three sources of audible roughness:
//
//   1. Linear, integer-advance resampling. `convertAtRatePlusFromLeft` used
//      floor/ceil on a block-local sample index, and `*consumed` was set to
//      `ceil(last * rate)`. That discards the sub-sample fraction between
//      blocks, so any steady pitch produces a small-amplitude saw-tooth at
//      the block boundary -> "whistle" / "zipper" noise.
//
//   2. Abrupt speed-rate change at the block boundary. Each UI timer tick
//      (~100 Hz) replaces `_speedRate` with a new value that is then applied
//      for the whole next 512-sample block. The pitch has an audible stair.
//
//   3. A hard gate at `speedRate == 0.0`: wet signal was zeroed, which is
//      not how a record behaves (a stopped record is silent because it has
//      no velocity, not because a gate is closed). The current code even
//      needed a whole extra fade-transition state (`_isSpeedChanging`) to
//      hide the resulting clicks when the user crossed zero.
//
// The xwax player (player.c) avoids all three by:
//
//   - cubic Hermite interpolation on a double-precision read-pointer that is
//     never rounded between blocks (`sample += step` inside the per-sample
//     loop),
//   - linear per-sample ramps of gain across the output block
//     (`vol += gradient`),
//   - making the wet volume proportional to |pitch| (`target_volume =
//     fabs(pitch) * VOLUME`), so a stopped record is naturally silent and
//     a crossing of zero is click-free.
//
// This file ports all three ideas into Going Zero's ring-buffer world,
// keeping the existing start-of-scratch and end-of-scratch fades (which
// are still useful for the discontinuity that happens when the user first
// grabs the record or releases it), but removes the fragile mid-scratch
// "speed changing" transition, which is now redundant.
//
// ---------------------------------------------------------------------------

// One-pole time constant for the audio-rate speed smoother. The value is in
// "blend rate per sample at 44.1 kHz" and corresponds to a time constant of
// roughly 3 ms, which is short enough that the user still feels the scratch
// tracking the mouse, but long enough to merge successive UI timer ticks
// into a continuous ramp.
#define SPEED_SMOOTH_ALPHA     (1.0 / 128.0)

// One-pole time constant for the pitch-driven wet-gain smoother. A bit
// longer than the speed smoother so that micro-oscillations around zero
// speed don't re-open the gate instantly.
#define GAIN_SMOOTH_ALPHA      (1.0 / 256.0)

// DC blocker pole. 0.995 corresponds to a ~35 Hz high-pass at 44.1 kHz,
// well below audio but enough to kill any residual DC / rumble produced
// by the resampler when the record is moved back and forth.
#define DC_BLOCKER_R           (0.995f)

// Wet-gain curve: target gain = min(|speed| * GAIN_SLOPE, 1.0).
// A slope of 4 means the record reaches full wet volume at |speed| = 0.25,
// and fades to silence linearly below that. This mirrors xwax's
// target_volume = fabs(pitch) * VOLUME trick (with VOLUME = 7/8) but is
// shaped to be more forgiving for slow hand motion.
#define GAIN_SLOPE             (4.0)

// Below this |speed| the record is considered "essentially stopped": the
// wet gain is clamped to 0 at the *target* so the smoother can coast to
// true silence. This keeps us click-free as speed crosses zero.
#define STOPPED_SPEED_EPSILON  (1.0e-4)

@interface TurnTableController ()
@end

@implementation TurnTableController

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
    
    _smoothedSpeed = 1.0;
    _subSamplePos  = 0.0;
    _wetGain       = 1.0;
    
    _dcInL = _dcOutL = 0.0f;
    _dcInR = _dcOutR = 0.0f;
    
    _isScratching      = NO;
    _isScratchStarting = NO;
    _isScratchEnding   = NO;
    _isFadingOut       = NO;
    _isFadingIn        = NO;
    _fadeOutCounter    = 0;
    _fadeInCounter     = 0;
}

// ---------------------------------------------------------------------------
// UI -> audio-thread glue
// ---------------------------------------------------------------------------

-(void)turnTableSpeedRateChanged{
    double newSpeedRate = [_turnTableView speedRate];
    _speedRate = newSpeedRate;
    
    // Case A: the user grabbed the record while a release-fade was in
    // progress. Cancel the release-fade and start a grab-fade instead.
    if (_isScratchEnding && newSpeedRate != 1.0){
        _isScratchEnding   = NO;
        _isScratchStarting = YES;
        _isFadingOut       = YES;
        _fadeOutCounter    = FADE_SAMPLE_NUM;
        return;
    }
    
    // Case B: the user released the record while a grab-fade was in
    // progress. Cancel the grab-fade and start a release-fade instead.
    if (_isScratchStarting && newSpeedRate == 1.0){
        _isScratchStarting = NO;
        _isScratchEnding   = YES;
        _isFadingOut       = YES;
        _fadeOutCounter    = FADE_SAMPLE_NUM;
        return;
    }
    
    // Case C: plain scratch starting (normal -> scratch). Short fade of
    // the pass-through so the user doesn't hear the ~1-sample
    // discontinuity as we switch to reading the ring at a different rate.
    if (!_isScratching && !_isFadingOut && newSpeedRate != 1.0){
        _isScratchStarting = YES;
        _isFadingOut       = YES;
        _fadeOutCounter    = FADE_SAMPLE_NUM;
        return;
    }
    
    // Case D: plain scratch ending (scratch -> normal).
    if (_isScratching && !_isFadingOut && newSpeedRate == 1.0){
        _isScratchEnding = YES;
        _isFadingOut     = YES;
        _fadeOutCounter  = FADE_SAMPLE_NUM;
        return;
    }
    
    // Case E: mid-scratch speed update. Nothing to do -- the audio-thread
    // smoother picks up the new target next block. Crossing zero is now
    // handled by the pitch-proportional wet gain, not by muting, so no
    // click-hiding fade is needed.
}

- (IBAction)wetVolumeChanged:(id)sender {
    _wetVolume = [_sliderWetVolume floatValue];
}

- (IBAction)dryVolumeChanged:(id)sender {
    _dryVolume = [_sliderDryVolume floatValue];
}

// ---------------------------------------------------------------------------
// Cubic Hermite (Catmull-Rom-ish) interpolation, ported from xwax player.c.
//
// y[0..3] are 4 consecutive samples; mu in [0,1] is the fractional position
// between y[1] and y[2]. This gives a C^1 curve which is dramatically
// smoother than straight-line interpolation, especially at the low pitches
// you hit during a real scratch.
// ---------------------------------------------------------------------------
static inline float cubicInterpolate(float y0, float y1, float y2, float y3, double mu){
    double mu2 = mu * mu;
    double a0 = (double)y3 - (double)y2 - (double)y0 + (double)y1;
    double a1 = (double)y0 - (double)y1 - a0;
    double a2 = (double)y2 - (double)y0;
    double a3 = (double)y1;
    return (float)((mu * mu2 * a0) + (mu2 * a1) + (mu * a2) + a3);
}

// ---------------------------------------------------------------------------
// Core resampler. Walks a double-precision read head across the ring buffer,
// ramping the speed from startSpeed to endSpeed across the output block.
//
//   - `baseL` / `baseR` point at the ring buffer's current read pointer.
//     The ring buffer is mirrored on both sides (see RingBuffer.m
//     allocMirrorBuf2) so we can safely read `[-1, numSamples*rate + 2]`
//     around the read pointer without bounds-checking inside the loop.
//   - `subPos` is the fractional position inside the first input sample
//     when we start. It is updated in-place so successive blocks continue
//     seamlessly.
//   - `*consumed` returns the integer number of input samples the ring
//     pointer should advance by after the block. The leftover fraction
//     stays in *subPos.
// ---------------------------------------------------------------------------
-(void)resampleFromLeft:(float *)baseL right:(float *)baseR
              toDstLeft:(float *)dstL dstRight:(float *)dstR
               samples:(UInt32)numSamples
            startSpeed:(double)startSpeed
              endSpeed:(double)endSpeed
                subPos:(double *)subPos
              consumed:(SInt32 *)consumed{
    
    double pos   = *subPos;
    double speed = startSpeed;
    double dSpeed = (endSpeed - startSpeed) / (double)numSamples;
    
    // integerBase is the offset into baseL/baseR of the sample that we
    // treat as "y[1]" in the cubic window. It advances by floor(pos) each
    // iteration once pos crosses 1.0.
    SInt32 integerBase = 0;
    
    for (UInt32 i = 0; i < numSamples; i++){
        // Integer-part carry: if pos has walked past the current sample
        // (forward or backward), shift the cubic window.
        while (pos >= 1.0){
            pos       -= 1.0;
            integerBase += 1;
        }
        while (pos < 0.0){
            pos       += 1.0;
            integerBase -= 1;
        }
        
        // 4-tap window centred on integerBase. Ring is mirrored on both
        // sides, so negative indices are valid for reverse scratching.
        float l0 = baseL[integerBase - 1];
        float l1 = baseL[integerBase    ];
        float l2 = baseL[integerBase + 1];
        float l3 = baseL[integerBase + 2];
        
        float r0 = baseR[integerBase - 1];
        float r1 = baseR[integerBase    ];
        float r2 = baseR[integerBase + 1];
        float r3 = baseR[integerBase + 2];
        
        dstL[i] = cubicInterpolate(l0, l1, l2, l3, pos);
        dstR[i] = cubicInterpolate(r0, r1, r2, r3, pos);
        
        pos   += speed;
        speed += dSpeed;
    }
    
    // Normalise: whatever integer samples we walked past belongs to
    // *consumed, the remainder stays in *subPos for next block.
    while (pos >= 1.0){
        pos       -= 1.0;
        integerBase += 1;
    }
    while (pos < 0.0){
        pos       += 1.0;
        integerBase -= 1;
    }
    
    *subPos   = pos;
    *consumed = integerBase;
}

// ---------------------------------------------------------------------------
// Normal-playback path (no scratch). Applies optional fade-in on the wet
// signal, which is just the input pass-through at this point.
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Fade-out phase for scratch start: we are still passing audio through,
// fading it out; when the counter hits zero we flip into the scratch state
// and hand the remaining samples to processScratchState.
// ---------------------------------------------------------------------------
-(UInt32)processFadeOutForScratchStart:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
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
            // Enter the scratch state. Align the ring read head to now,
            // reset the sub-sample fraction, and let the smoother take
            // over from 1.0 to the new target speed.
            [_ring follow];
            _subSamplePos      = 0.0;
            _smoothedSpeed     = 1.0;
            _wetGain           = 1.0;
            _isScratching      = YES;
            _isFadingOut       = NO;
            _isFadingIn        = YES;
            _fadeInCounter     = 0;
            _isScratchStarting = NO;
            return i + 1;
        }
    }
    return n;
}

// ---------------------------------------------------------------------------
// Fade-out phase for scratch end: we are still scratching, fading the
// scratched wet out; when the counter hits zero we switch to normal
// playback (which starts its own fade-in).
// ---------------------------------------------------------------------------
-(UInt32)processFadeOutForScratchEnd:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    UInt32 n = (numSamples < _fadeOutCounter) ? numSamples : _fadeOutCounter;
    
    // Resample the block using the smoother exactly like processScratchState,
    // but with an extra linear fade-out on top of the wet.
    [self processScratchBlock:leftBuf right:rightBuf samples:n applyExtraFade:YES];
    
    // Walk the fade counter and apply the fade to the already-mixed output
    // above. processScratchBlock already applied the fade via applyExtraFade,
    // so here we just check if we've reached the end.
    if (_fadeOutCounter == 0){
        [_ring follow];
        _subSamplePos    = 0.0;
        _smoothedSpeed   = 1.0;
        _wetGain         = 0.0;
        _isScratching    = NO;
        _isFadingOut     = NO;
        _isFadingIn      = YES;
        _fadeInCounter   = 0;
        _isScratchEnding = NO;
        return n;
    }
    return n;
}

// ---------------------------------------------------------------------------
// Main scratch processing block.
//
// This is where the xwax-inspired smoothing happens:
//
//   1. The *target* speed is _speedRate (written by the UI thread).
//   2. Each sample, _smoothedSpeed takes a small step toward that target
//      (one-pole). That gives us a click-free pitch curve even when the
//      mouse is jittering.
//   3. The target wet gain is |_smoothedSpeed| * GAIN_SLOPE clamped to 1.
//      That is xwax's "target_volume = fabs(pitch) * VOLUME" trick. The
//      wet gain also coasts toward the target with another one-pole.
//   4. Resampling happens in a single batch at the start/end of the
//      block with a linear speed ramp, so the per-sample cost stays low
//      and we still get sub-block smoothing of the pitch.
//   5. A tiny high-pass removes any DC the resampler might produce when
//      the user rapidly reverses direction across a loud sample.
// ---------------------------------------------------------------------------
-(void)processScratchBlock:(float *)leftBuf right:(float *)rightBuf
                   samples:(UInt32)numSamples
            applyExtraFade:(BOOL)applyExtraFade{
    if (numSamples == 0) return;
    
    // --- (a) compute per-sample smoother trajectories for this block ---
    //
    // We unroll the one-pole smoothers into:
    //    start value (= current smoother state)
    //    end   value (= state after n samples of smoothing toward target)
    //
    // The resampler interpolates speed linearly between start and end, and
    // we apply the gain ramp linearly over the block. This is a very good
    // approximation of a true per-sample one-pole over ~50 sample blocks
    // and is dramatically cheaper than running the smoother inside the
    // resampler loop.
    double targetSpeed = _speedRate;
    double speedStart  = _smoothedSpeed;
    double speedEnd    = speedStart;
    for (UInt32 i = 0; i < numSamples; i++){
        speedEnd += (targetSpeed - speedEnd) * SPEED_SMOOTH_ALPHA;
    }
    
    double absMean    = 0.5 * (fabs(speedStart) + fabs(speedEnd));
    double targetGain = absMean * GAIN_SLOPE;
    if (targetGain > 1.0)    targetGain = 1.0;
    if (absMean < STOPPED_SPEED_EPSILON) targetGain = 0.0;
    
    double gainStart = _wetGain;
    double gainEnd   = gainStart;
    for (UInt32 i = 0; i < numSamples; i++){
        gainEnd += (targetGain - gainEnd) * GAIN_SMOOTH_ALPHA;
    }
    
    // --- (b) resample the wet block (cubic, sub-sample accurate) -------
    
    float *baseL = [_ring readPtrLeft];
    float *baseR = [_ring readPtrRight];
    
    SInt32 consumed = 0;
    
    if (baseL != NULL && baseR != NULL){
        [self resampleFromLeft:baseL right:baseR
                     toDstLeft:_tempLeftPtr dstRight:_tempRightPtr
                      samples:numSamples
                   startSpeed:speedStart
                     endSpeed:speedEnd
                       subPos:&_subSamplePos
                     consumed:&consumed];
    }else{
        // Ring not ready: output silence for the wet branch.
        memset(_tempLeftPtr,  0, sizeof(float) * numSamples);
        memset(_tempRightPtr, 0, sizeof(float) * numSamples);
    }
    
    // --- (c) DC blocker + wet/dry mix with linear ramps ---------------
    
    double gain = gainStart;
    double dGain = (gainEnd - gainStart) / (double)numSamples;
    
    float dcInL  = _dcInL;
    float dcOutL = _dcOutL;
    float dcInR  = _dcInR;
    float dcOutR = _dcOutR;
    
    // Extra linear fade-out on top of the per-sample gain when asked
    // (used during scratch-end fade-out). Start and end are derived
    // from _fadeOutCounter and the current block size.
    double extraFade  = applyExtraFade ? (_fadeOutCounter / (double)FADE_SAMPLE_NUM) : 1.0;
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
    
    _dcInL = dcInL;  _dcOutL = dcOutL;
    _dcInR = dcInR;  _dcOutR = dcOutR;
    
    // --- (d) commit smoother state and ring advance -------------------
    
    _smoothedSpeed = speedEnd;
    _wetGain       = gainEnd;
    [_ring advanceReadPtrSample:consumed];
    
    if (applyExtraFade){
        if (_fadeOutCounter >= numSamples){
            _fadeOutCounter -= numSamples;
        }else{
            _fadeOutCounter = 0;
        }
    }
}

// Convenience wrapper used by the top-level dispatcher.
-(void)processScratchState:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    [self processScratchBlock:leftBuf right:rightBuf samples:numSamples applyExtraFade:NO];
}

// ---------------------------------------------------------------------------
// Top-level dispatcher. Exactly one of four states is active:
//   - scratch starting (fading out pass-through, then scratch)
//   - scratch ending   (fading out scratched wet, then pass-through)
//   - scratching       (smoothed resampler)
//   - normal           (pass-through)
// ---------------------------------------------------------------------------
-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    
    // 1. Always write the current input to the ring -- the scratch state
    //    needs a recent history to read from.
    {
        float *dstL = [_ring writePtrLeft];
        float *dstR = [_ring writePtrRight];
        memcpy(dstL, leftBuf,  numSamples * sizeof(float));
        memcpy(dstR, rightBuf, numSamples * sizeof(float));
        [_ring advanceWritePtrSample:numSamples];
    }
    
    // 2. Fade-out phase
    if (_isFadingOut){
        UInt32 processed = 0;
        if (_isScratchStarting){
            processed = [self processFadeOutForScratchStart:leftBuf right:rightBuf samples:numSamples];
            if (processed < numSamples){
                [self processScratchState:&leftBuf[processed]
                                    right:&rightBuf[processed]
                                  samples:numSamples - processed];
            }
        }else if (_isScratchEnding){
            processed = [self processFadeOutForScratchEnd:leftBuf right:rightBuf samples:numSamples];
            if (!_isFadingOut && processed < numSamples){
                [self processNormalState:&leftBuf[processed]
                                   right:&rightBuf[processed]
                                 samples:numSamples - processed];
            }
        }
        return;
    }
    
    // 3. Steady state
    if (_isScratching){
        [self processScratchState:leftBuf right:rightBuf samples:numSamples];
    }else{
        [self processNormalState:leftBuf right:rightBuf samples:numSamples];
    }
}

@end
