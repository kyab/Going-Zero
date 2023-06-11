//
//  LookUpController.h
//  Going Zero
//
//  Created by koji on 2023/05/27.
//  Copyright © 2023 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Lookup.h"
#import "TouchView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LookUpController : NSViewController<TouchViewDelegate>{
    Lookup *_lookup;
    __weak IBOutlet NSButton *_btnLookup;
    __weak IBOutlet TouchView *_touchView;
    Boolean _btnLookupPressing;
}

-(void)setLookUp:(Lookup *)lookup;


@end

NS_ASSUME_NONNULL_END
