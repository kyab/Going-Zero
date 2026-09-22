//
//  MelodizerController.h
//  Going Zero
//
//  Created by koji on 2026/08/24.
//  Copyright © 2026 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Melodizer.h"

NS_ASSUME_NONNULL_BEGIN

@interface MelodizerController : NSViewController {
    Melodizer *_melodizer;
    __weak IBOutlet NSButton *_chkActive;
}
-(void)setMelodizer:(Melodizer *)melodizer;
-(void)setTranspose:(float)pitchShift;
-(void)stopTranspose;

@end

NS_ASSUME_NONNULL_END

