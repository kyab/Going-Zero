//
//  LookUpController.h
//  Going Zero
//
//  Created by koji on 2023/05/27.
//  Copyright © 2023 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LookUp.h"
#import "TouchView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LookUpController : NSViewController<TouchViewDelegate>{
    LookUp *_lookUp;
    __weak IBOutlet NSButton *_btnLookUp;
    __weak IBOutlet TouchView *_touchView;
    Boolean _btnLookUpPressing;
}

-(void)setLookUp:(LookUp *)lookUp;


@end

NS_ASSUME_NONNULL_END
