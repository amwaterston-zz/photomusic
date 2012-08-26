//
//  AppDelegate.h
//  musictures
//
//  Created by Alex Waterston on 25/08/2012.
//  Copyright (c) 2012 Alex Waterston. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PdBase.h"

@class PdTestViewController;
@class PdAudioController;

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, PdReceiverDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ViewController *viewController;
@property (strong, nonatomic) PdAudioController *audioController;

@end
