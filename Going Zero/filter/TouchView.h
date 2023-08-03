//
//  TouchView.h
//  Going Zero
//
//  Created by koji on 2023/06/04.
//  Copyright © 2023 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Lookup.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TouchViewDelegate <NSObject>
@optional
-(void)touchViewMouseDown:(double) xRatio;
-(void)touchViewMouseUp;
@end

@interface TouchView : NSView{
    
    id<TouchViewDelegate> _delegate;
    Lookup *_lookup;
    NSTimer *_timer;

}


-(void)setDelegate:(id<TouchViewDelegate>)delegate;
-(void)setLookup:(Lookup *)lookup;


@end

NS_ASSUME_NONNULL_END
