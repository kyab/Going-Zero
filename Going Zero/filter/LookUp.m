//
//  LookUp.m
//  Going Zero
//
//  Created by koji on 2023/05/24.
//  Copyright © 2023 kyab. All rights reserved.
//

#import "LookUp.h"

@implementation LookUp

-(id)init{
    self = [super init];
    _ring = [[RingBuffer alloc] init];
    _duration = 0;
    return self;
}
-(void)startMark{

}

-(void)startLooping{}
@end
