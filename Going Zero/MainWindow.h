//
//  MainWindow.h
//  Going Zero
//
//  Created by koji on 2024/04/04.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MainWindowKeyDelegate <NSObject>
@optional
- (Boolean)mainWindowKeyDown:(NSEvent *)event;
- (Boolean)mainWindowKeyUp:(NSEvent *)event;
@end

@interface MainWindow : NSWindow{
    id<MainWindowKeyDelegate> _keyDelegate;
}

-(void)setKeyDelegate:(id<MainWindowKeyDelegate>)keyDelegate;

@end

NS_ASSUME_NONNULL_END
