//
//  QuickCueController.h
//  Going Zero
//
//  Created by kyab on 2021/06/15.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QuickCue.h"

NS_ASSUME_NONNULL_BEGIN

@interface QuickCueController : NSViewController{
    QuickCue *_quickCue;
    __weak IBOutlet NSButton *_btnCue1;
    __weak IBOutlet NSButton *_btnCue2;
    __weak IBOutlet NSButton *_btnClear1;
    __weak IBOutlet NSButton *_btnClear2;
    __weak IBOutlet NSButton *_btnExit;
    
    NSButton *_btnCues[2];
}

-(void)setQuickCue:(QuickCue *)quickCue;



@end

NS_ASSUME_NONNULL_END
