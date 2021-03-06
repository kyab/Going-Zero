//
//  TurnTableView.h
//  Fluent Scratch
//
//  Created by kyab on 2017/05/08.
//  Copyright © 2017年 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RingBuffer.h"

@protocol TurnTableDelegate <NSObject>
@optional
-(void)turnTableSpeedRateChanged;
@end


@interface TurnTableView : NSView{
    BOOL _pressing;
    BOOL _MIDIScratching;
    BOOL _MIDITouching;
    double _currentRad;
    double _currentRadPlay;
    
    RingBuffer *_ring;
    
    CGFloat _startOffsetRad;
    
    NSTimer *_timer;
    NSTimer *_timer2;   //scratch monitor
    NSTimer *_timer3;   //scratch monitor(MIDI)
    
    NSTimeInterval _prevSec;
    NSTimeInterval _lastUpdateSec;
    double _prevSpeedRate;
    double _prevRad;
    BOOL _prevRadValid;
    
    CGFloat _prevX;
    CGFloat _prevY;
    
    double _speedRate;
    double _history[10];
    double _accel;
    
    BOOL _reverse;
    
    id<TurnTableDelegate> _delegate;
    
    
}

-(void)setDelegate:(id<TurnTableDelegate>)delegate;
-(void)setRingBuffer:(RingBuffer *)ring;
-(void)start;
-(void)stop;
-(double)speedRate;
-(void)setReverse:(BOOL)reverse;
-(void)onMIDITouchStart;
-(void)onMIDITouchStop;
-(void)onMIDIScratch:(int)number value:(int)value chan:(int)chan;
@end
