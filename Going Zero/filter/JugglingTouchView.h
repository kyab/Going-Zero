//
//  JugglingTouchView.h
//  Going Zero
//
//  Created by koji on 2024/02/19.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol JugglingTouchViewDelegate <NSObject>
@optional
-(void)jugglingTouchViewMouseDown:(UInt32) beatRegionDivide8;
-(void)touchViewMouseUp;
@end

@interface JugglingTouchView : NSView{
    
    id<JugglingTouchViewDelegate> _delegate;
}

-(void)setDelegate:(id<JugglingTouchViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
