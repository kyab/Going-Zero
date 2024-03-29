//
//  TurnTableController.h
//  Going Zero
//
//  Created by yoshioka on 2024/01/24.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RingBuffer.h"
#import "TurnTableView.h"
#import "MiniFader.h"

NS_ASSUME_NONNULL_BEGIN

@interface TurnTableController : NSViewController <TurnTableDelegate>{
    
    RingBuffer *_ring;
    MiniFaderIn *_faderIn;
    __weak IBOutlet TurnTableView *_turnTableView;
    
    float _dryVolume;
    float _wetVolume;
    
    __weak IBOutlet NSSlider *_sliderWetVolume;
    __weak IBOutlet NSSlider *_sliderDryVolume;
    
    
    double _speedRate;
}

-(void)setRingBuffer:(RingBuffer *)ring;
-(void)setMiniFaderIn:(MiniFaderIn *)faderIn;
-(float)wetVolume;
-(float)dryVolume;
-(double)speedRate;

@end

NS_ASSUME_NONNULL_END
