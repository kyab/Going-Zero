//
//  SimpleReverbController.h
//  Going Zero
//
//  Created by kyab on 2021/12/14.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SimpleReverb.h"

NS_ASSUME_NONNULL_BEGIN

@interface SimpleReverbController : NSViewController{
    SimpleReverb *_simpleReverb;
    __weak IBOutlet NSButton *_chkOnOff;
}

-(void)setSimpleReverb:(SimpleReverb *)simpleReverb;

@end

NS_ASSUME_NONNULL_END
