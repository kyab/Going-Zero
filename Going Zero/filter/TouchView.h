//
//  TouchView.h
//  Going Zero
//
//  Created by koji on 2023/06/04.
//  Copyright © 2023 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TouchViewDelegate <NSObject>
@optional
-(void)touchViewMouseDown:(double) xRatio;
-(void)touchViewMouseUp;
@end

@interface TouchView : NSView{
    
    id<TouchViewDelegate> _delegate;
}


-(void)setDelegate:(id<TouchViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
