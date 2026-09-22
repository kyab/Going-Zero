//
//  JugglingTouchView.m
//  Going Zero
//
//  Created by koji on 2024/02/19.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "JugglingTouchView.h"

static NSString *NSTouchPhaseDescription(NSTouchPhase phase) {
    switch (phase) {
        case NSTouchPhaseBegan: return [NSString stringWithFormat:@"NSTouchPhaseBegan(%lu)", (unsigned long)phase];
        case NSTouchPhaseMoved: return [NSString stringWithFormat:@"NSTouchPhaseMoved(%lu)", (unsigned long)phase];
        case NSTouchPhaseStationary: return [NSString stringWithFormat:@"NSTouchPhaseStationary(%lu)", (unsigned long)phase];
        case NSTouchPhaseEnded: return [NSString stringWithFormat:@"NSTouchPhaseEnded(%lu)", (unsigned long)phase];
        case NSTouchPhaseCancelled: return [NSString stringWithFormat:@"NSTouchPhaseCancelled(%lu)", (unsigned long)phase];
        default: return [NSString stringWithFormat:@"NSTouchPhase(%lu)", (unsigned long)phase];
    }
}

@implementation JugglingTouchView

- (void)awakeFromNib{
    [self setAllowedTouchTypes:NSTouchTypeMaskDirect | NSTouchTypeMaskIndirect];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [NSColor.blackColor set];
    NSRectFill(self.bounds);
}

-(void)setDelegate:(id<JugglingTouchViewDelegate>)delegate{
    _delegate = delegate;
}

- (void)mouseDown:(NSEvent *)event{
    //get location on this view
    NSPoint l = [event locationInWindow];
    NSPoint location = [self convertPoint:l fromView:nil];
    CGFloat pixelsPerRegion = self.bounds.size.width / 16.0;
    UInt32 beatRegionDivide16 = (UInt32)(location.x / pixelsPerRegion);
        
    [_delegate jugglingTouchViewMouseDown:beatRegionDivide16];
}

-(void)mouseUp:(NSEvent *)event{
    [_delegate jugglingTouchViewMouseUp];
}

- (void)handle2FingerTouchForEventType:(NSString *)eventType event:(NSEvent *)event {
    NSSet<NSTouch *> *touches = [event touchesMatchingPhase:NSTouchPhaseAny inView:self];
    if (touches.count != 2){
        return;
    }
    
    double sumX = 0.0;
    for (NSTouch *touch in touches) {
        sumX += touch.normalizedPosition.x;
    }
    double centroidX = sumX / 2.0;  //left: 0.0, right: 1.0 on TrackPad
    
    UInt32 beatRegionDivide16 = (UInt32)(centroidX * 16);
//    NSLog(@"Touch(%@). region=%u, centroid x = %f",eventType, (unsigned int)beatRegionDivide16, centroidX );
    
    if ([eventType  isEqual: @"touchesBegan"]){
        [_delegate jugglingTouchViewTouchStart:beatRegionDivide16];
    } else if ([eventType  isEqual: @"touchesMoved"]){
        [_delegate jugglingTouchViewTouchMove:beatRegionDivide16];
    } else{
        [_delegate jugglingTouchViewTouchEnd];
    }
    
}

- (void)touchesBeganWithEvent:(NSEvent *)event {
    NSSet<NSTouch *> *touches = [event touchesMatchingPhase:NSTouchPhaseAny inView:self];
    if (touches.count == 2){
        [self handle2FingerTouchForEventType:@"touchesBegan" event:event];
    }
}

- (void)touchesMovedWithEvent:(NSEvent *)event {
    NSSet<NSTouch *> *touches = [event touchesMatchingPhase:NSTouchPhaseAny inView:self];
    if (touches.count == 2){
        [self handle2FingerTouchForEventType:@"touchesMoved" event:event];
    }
}

- (void)touchesEndedWithEvent:(NSEvent *)event {
    NSSet<NSTouch *> *touches = [event touchesMatchingPhase:NSTouchPhaseAny inView:self];
    if (touches.count == 2){
        [self handle2FingerTouchForEventType:@"touchesEnded" event:event];
    }
}

- (void)touchesCancelledWithEvent:(NSEvent *)event {
    NSSet<NSTouch *> *touches = [event touchesMatchingPhase:NSTouchPhaseAny inView:self];
    if (touches.count == 2){
        [self handle2FingerTouchForEventType:@"touchesCancelled" event:event];
    }
}


@end
