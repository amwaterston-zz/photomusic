//
//  ViewController.h
//  musictures
//
//  Created by Alex Waterston on 25/08/2012.
//  Copyright (c) 2012 Alex Waterston. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "PdBase.h"

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) BOOL useFrontCamera;
@property (nonatomic) int note;

- (void)initCapture;
- (IBAction)musicIt:(id)sender;

@end
