//
//  ReverseTurntableView.h
//  Going Zero
//
//  Created by kyab on 2021/06/13.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReverseTurntableView : NSView{
    float _currentRad;
    Boolean _reverse;
    NSTimer *_timer;
}

-(void)startReverse;
-(void)stopReverse;

@end

NS_ASSUME_NONNULL_END
