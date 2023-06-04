//
//  LookUpController.h
//  Going Zero
//
//  Created by koji on 2023/05/27.
//  Copyright © 2023 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LookUp.h"

NS_ASSUME_NONNULL_BEGIN

@interface LookUpController : NSViewController{
    LookUp *_lookUp;
    __weak IBOutlet NSButton *_btnLookUp;
    Boolean _btnLookUpPressing;
}

-(void)setLookUp:(LookUp *)lookUp;


@end

NS_ASSUME_NONNULL_END
