//
//  BeatLookupController.h
//  Going Zero
//
//  Created by yoshioka on 2024/01/31.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BeatLookup.h"

NS_ASSUME_NONNULL_BEGIN

@interface BeatLookupController : NSViewController{
    BeatLookup *_beatLookup;
}

-(void)setBeatLookup:(BeatLookup *)beatLookup;

@end

NS_ASSUME_NONNULL_END
