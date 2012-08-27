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
@synthesize colourView;
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
    [self setColourView:nil];
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

- (IBAction)tap {
    [PdBase sendBangToReceiver:@"tap"];
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


-(void)playNoteRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b inQuad:(NSInteger)quad {
    
    [PdBase sendFloat:r toReceiver:[NSString stringWithFormat:@"q%dr", quad]];
    [PdBase sendFloat:g toReceiver:[NSString stringWithFormat:@"q%dg", quad]];
    [PdBase sendFloat:b toReceiver:[NSString stringWithFormat:@"q%db", quad]];
}

struct pixel {
    unsigned char b, g, r, a;
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
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    
        CGFloat red[2][2] = {0};
        CGFloat green[2][2] = {0};
        CGFloat blue[2][2] = {0};
        
        struct pixel* pix = (struct pixel*)baseAddress;
        
        CGFloat mult[2] = { 1.0f/4.0f, 3.0f/4.0f };
        for (int x = 0; x < 2; x++) {
            for (int y = 0; y < 2; y++) {
                int p = (int)(width * mult[x] + (width * mult[y] * height));
                red[x][y] = pix[p].r;
                green[x][y] = pix[p].g;
                blue[x][y] = pix[p].b;
            }
        }
        /*
        NSUInteger numberOfPixels = (width / 2) * (height / 2);
        for (int x = 0; x < width; x ++) {
            for (int y = 0; y < height; y ++) {
                int p = y * width + x;
                int qx, qy;
                if ( x < width / 2) {
                    qx = 0;
                } else {
                    qx = 1;
                }
                
                if ( y < height / 2) {
                    qy = 0;
                } else {
                    qy = 1;
                }
                
                //NSLog (@"pix[%d].r = %d", p, pix[p].r);
                
                red[qx][qy] += pix[p].r;
                green[qx][qy] += pix[p].g;
                blue[qx][qy] += pix[p].b;
            }
        }
        */
        for (int qx = 0; qx < 2; qx++) {
            for (int qy = 0; qy < 2; qy++) {
                red[qx][qy] = (red[qx][qy] * 1.0f); // / (numberOfPixels);
                green[qx][qy] = (green[qx][qy] * 1.0f); // / (numberOfPixels);
                blue[qx][qy] = (blue[qx][qy] * 1.0f); // / (numberOfPixels);
                //NSLog(@"Q[%d, %d] red = %.2f, green = %.2f, blue = %.2f", qx, qy, red[qx][qy], green[qx][qy], blue[qx][qy]);
                [self playNoteRed:red[qx][qy] green:green[qx][qy] blue:blue[qx][qy] inQuad:qx+(qy*2)];
                UIView *v = [self.colourView objectAtIndex:qx+(qy*2)];
                [v performSelectorOnMainThread:@selector(setBackgroundColor:) withObject:[UIColor colorWithRed:red[qx][qy] / 256.0f green:green[qx][qy] / 256.0f blue:blue[qx][qy] / 256.0f alpha:1.0f] waitUntilDone:NO];
            }
        }
        
        /*We release some components*/
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        /*We unlock the  image buffer*/
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    }

}

@end
