//
//  AppDelegate.h
//  Going Zero
//
//  Created by kyab on 2021/05/29.
//  Copyright © 2021 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>{
    
    __weak IBOutlet AppController *_controller;
}


@end

