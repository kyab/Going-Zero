//
//  TurnTableController.h
//  Going Zero
//
//  Created by kyab on 2021/06/18.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TurnTableEx.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TurnTableViewExDelegate <NSObject>
@optional
-(void)turnTableViewExSpeedRateChanged;
-(void)turnTableViewExDidSpeedRateReset;
@end

@interface TurnTableViewEx : NSView{
    Boolean _pressing;
    float _pressingR;
    
    float _preRad;
    float _preX;
    float _preY;
    NSTimeInterval _preSec;
    
    id<TurnTableViewExDelegate> _delegate;
    
    float _speedRate;
}

-(void)setDelegate:(id<TurnTableViewExDelegate>) delegate;
-(float)speedRate;
@end

@interface TurnTableController : NSViewController{
    
    __weak IBOutlet TurnTableViewEx *_turnTableViewEx;
    TurnTableEx *_turnTableEx;
    __weak IBOutlet NSSlider *_sliderSpeedRate;
}

-(void)setTurnTableEx:(TurnTableEx *)turnTableEx;

@end



NS_ASSUME_NONNULL_END
