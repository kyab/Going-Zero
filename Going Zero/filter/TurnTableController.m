//
//  TurnTableController.m
//  Going Zero
//
//  Created by kyab on 2021/06/18.
//  Copyright © 2021 kyab. All rights reserved.
//

#import "TurnTableController.h"


@implementation TurnTableViewEx

- (void)awakeFromNib{
    _speedRate = 1.0;
    _pressing = NO;
}


-(void)setDelegate:(id<TurnTableViewExDelegate>) delegate{
    _delegate = delegate;
}

-(float)speedRate{
    return _speedRate;
}

- (void)drawRect:(NSRect)dirtyRect{
    [super drawRect:dirtyRect];

    CGFloat r1 = self.bounds.size.height/2 ;
    CGFloat r2 = self.bounds.size.width/2;
    CGFloat r = 0;
    if (r1 > r2){
        r = r2;
    }else{
        r = r1;
    }
    
    NSRect circleRect = NSMakeRect(
                                   self.bounds.size.width/2 - r,
                                   self.bounds.size.height/2 - r,
                                   2*r,
                                   2*r);
    
    NSBezierPath *circlePath = [NSBezierPath bezierPathWithOvalInRect:circleRect];
    

    [[NSColor grayColor] set];
    [circlePath fill];
}

-(NSPoint)eventLocation:(NSEvent *) theEvent{
    return [self convertPoint:theEvent.locationInWindow fromView:nil];
}

-(void)mouseDown___:(NSEvent *)theEvent{
    Boolean dragActive = YES;
    
    [self mouseDown:theEvent];
    
    while(dragActive){
        NSWindow *targetWindow = [self window];
        NSEvent *event = [targetWindow nextEventMatchingMask:NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
        if(!event){
            continue;
        }
        switch(event.type){
            case NSEventTypeLeftMouseDragged:
            {
                [self mouseDragged:event];
                NSLog(@"dragged");
            }
                break;
            case NSEventTypeLeftMouseUp:
            {
                [self mouseUp:event];
                NSLog(@"up");
                dragActive = NO;
            }
                break;
            default:
                break;
        }
    }
}

-(void)mouseDown:(NSEvent *)theEvent{
    
    CGFloat x = [self eventLocation:theEvent].x;
    CGFloat y = [self eventLocation:theEvent].y;
    
    x = x - self.bounds.size.width/2;
    y = y - self.bounds.size.height/2;
    
    _preX = x;
    _preY = y;
    
    
    CGFloat dist = sqrt(x*x + y*y);
    CGFloat r = self.bounds.size.height/2;
    
    if (dist <= r){
        _pressing = YES;
        _pressingR = dist;
        _preSec = [[NSDate now] timeIntervalSince1970];
        if (y < 0){
            _preRad = -_preRad + 2* M_PI;
        }
        
        [[NSCursor openHandCursor] set];
        [self setNeedsDisplay:YES];
    }else{
        _pressing = NO;
    }
}

-(void)mouseDragged:(NSEvent *)theEvent{
    if (_pressing == NO)return;
    
    CGFloat x = [self eventLocation:theEvent].x;
    CGFloat y = [self eventLocation:theEvent].y;
    
    x = x - self.bounds.size.width/2;
    y = y - self.bounds.size.height/2;
    
    float deltaX = x - _preX;
    float deltaY = y - _preY;
    
    float delta = sqrt(deltaX * deltaX + deltaY * deltaY);
    float circumference = 2 * M_PI * _pressingR;
    float theta = 2 * M_PI * delta / circumference;
    NSTimeInterval nowSec = [[NSDate now] timeIntervalSince1970];
    float radS = theta / (nowSec - _preSec);
    _preSec = nowSec;
    _speedRate = radS / (-33.3/60 * M_PI*2);  //ratio
    
    _preX = x;
    _preY = y;
    
    [_delegate turnTableViewExSpeedRateChanged];
    [self setNeedsDisplay:YES];
    
}

-(void)mouseUp:(NSEvent *)theEvent{
    _pressing = NO;
    _speedRate = 1.0f;
    [_delegate turnTableViewExDidSpeedRateReset];
    
    [[NSCursor arrowCursor] set];
    [self setNeedsDisplay:YES];
}

@end

@implementation TurnTableController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [_turnTableViewEx setDelegate:(id<TurnTableViewExDelegate>)self];
}

-(void)turnTableViewExSpeedRateChanged{
    [_turnTableEx setSpeedRate:[_turnTableViewEx speedRate]];
    
}

-(void)turnTableViewExDidSpeedRateReset{
    [_turnTableEx reset];
}

-(void)setTurnTableEx:(TurnTableEx *)turnTableEx{
    _turnTableEx = turnTableEx;
}
- (IBAction)speedSliderChanged:(id)sender {
    
    if([[NSApplication sharedApplication] currentEvent].type == NSEventTypeLeftMouseUp){
        [_sliderSpeedRate setFloatValue:1.0];
        [_turnTableEx reset];
        return;
    }

    
    float speedRate = [_sliderSpeedRate floatValue];
    if (speedRate == 1.0){
        [_turnTableEx reset];
    }else{
        [_turnTableEx setSpeedRate:speedRate];
    }
}
@end

    
