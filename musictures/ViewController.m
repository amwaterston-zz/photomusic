//
//  ViewController.m
//  musictures
//
//  Created by Alex Waterston on 25/08/2012.
//  Copyright (c) 2012 Alex Waterston. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize imageView;
@synthesize useFrontCamera, captureSession, stillImageOutput;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self initCapture];
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (AVCaptureDevice *)frontCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)backCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            return device;
        }
    }
    return nil;
}

- (void)shutDownCapture {
    [self.captureSession stopRunning];
    self.captureSession = nil;
}

- (void)initCapture {
    [self shutDownCapture];
    
    AVCaptureDevice *camera;
    if (useFrontCamera) {
        camera = [self frontCamera];
    } else {
        camera = [self backCamera];
    }
    
    if (camera == nil) {
        camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    NSError *error = nil;
    /*We setup the input*/
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput
                                          deviceInputWithDevice:camera
                                          error:&error];
    
    if (error != nil) {
        NSLog(@"ERROR: %@", error);
    }
    
    /*And we create a capture session*/
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetLow;
    
    /*We add input and output*/
    [self.captureSession addInput:captureInput];
    
    /*We setupt the output*/
    AVCaptureVideoPreviewLayer *captureOutput = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    
    captureOutput.frame = imageView.bounds;
    captureOutput.videoGravity = AVLayerVideoGravityResizeAspectFill;
    captureOutput.bounds=imageView.bounds;
    captureOutput.position=CGPointMake(CGRectGetMidX(imageView.bounds), CGRectGetMidY(imageView.bounds));
    
    captureOutput.orientation = AVCaptureVideoOrientationPortrait;
    
    [self.imageView.layer addSublayer:captureOutput];
    
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    //  pixel buffer format
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
                              kCVPixelBufferPixelFormatTypeKey, nil];
    videoDataOutput.videoSettings = settings;
    
    //  we need a serial queue for the video capture delegate callback
    dispatch_queue_t queue = dispatch_queue_create("com.bunnyherolabs.vampire", NULL);
    
    [videoDataOutput setSampleBufferDelegate:self queue:queue];
    [captureSession addOutput:videoDataOutput];
    
    dispatch_release(queue);
    
    /*We start the capture*/
    [self.captureSession startRunning];
}


-(void)playNoteRed:(int)r green:(int)g blue:(int)b {
    [PdBase sendFloat:r toReceiver:@"midinote"];
    [PdBase sendFloat:g toReceiver:@"midinote2"];
    [PdBase sendFloat:b toReceiver:@"midinote3"];
}

struct pixel {
    unsigned char r, g, b, a;
};

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        /*Lock the image buffer*/
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        /*Get information about the image*/
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        /*Create a CGImageRef from the CVImageBufferRef*/
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
        NSInteger red, green, blue;
        
        struct pixel* pix = (struct pixel*)baseAddress;
        
        NSUInteger numberOfPixels = width * height;
        for (int i=0; i<numberOfPixels; i++) {
            red += pix[i].r;
            green += pix[i].g;
            blue += pix[i].b;
        }
        
        red /= numberOfPixels;
        green /= numberOfPixels;
        blue/= numberOfPixels;
        
        NSLog(@"red %d", red);
        [self playNoteRed:(red / 256.0f) * 100.0f green:(green / 256.0f) * 100.0f blue:(blue / 256.0f) * 100.0f];
        
        /*We release some components*/
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        /*We unlock the  image buffer*/
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    }

}

@end
