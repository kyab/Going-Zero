//
//  WaveView.h
//  Going Zero
//
//  Created by kyab on 2021/06/03.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Viewer.h"
#import "RingBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface WaveView : NSView{
    Viewer *_viewer;
    NSTimer *_timer;
}

- (void)setViewer:(Viewer *)viewer;



@end

NS_ASSUME_NONNULL_END
