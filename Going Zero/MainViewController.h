//
//  MainViewController.h
//  Going Zero
//
//  Created by kyab on 2021/11/11.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MainViewController : NSViewController{
    Boolean _upPressed;
    Boolean _downPressed;
}

-(Boolean)isUpKeyPressed;
-(Boolean)isDownKeyPressed;

@end

NS_ASSUME_NONNULL_END
