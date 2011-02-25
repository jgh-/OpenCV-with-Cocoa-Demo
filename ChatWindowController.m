/*  
 *  Webcam/FaceTracking/Custom Views example project - jamesghurley<at>gmail.com
 *  This project emulates 1-on-1 video conferencing using modern Cocoa frameworks and techniques.
 *  
 *  ChatWindowController.h/.m - Manages a "video chat" instance.
 */

// TODO: Find camera resolution.

#import "ChatWindowController.h"
#import "CGImageWrapper.h"
#import "STUI.h"

#define FAST_SAMPLE_STRIDE       2    // wait SAMPLE_STRIDE-1 frames before sampling again.
#define SLOW_SAMPLE_STRIDE       5  
#define SPEED_CUTOFF             6.0  // weighted average speed above which we'll ignore movement.
#define DISTANCE_CUTOFF          0.1  // Percentage distance of the center of the face to the center of the screen 
                                      // before we start moving the PIP view.

#define hit_test(_cx,_cy,_r,_x,_y) ((pow(_cx-_x,2.0)+pow(_cy-_y,2.0))<pow(_r, 2.0))

// -----------------------------------------------------------------------------
// Private methods for ChatWindowController
// -----------------------------------------------------------------------------
@interface ChatWindowController (Private)

- (void) runAlertSheet: (NSString*) alertMessage withTitle: (NSString*) alertTitle;
- (void) alertDidEnd: (NSAlert*) alert returnCode: (int) returnCode contextInfo: (void*) contextInfo;
- (void) updateCameraLayer:(CGImageWrapper*) image;

@end
// -----------------------------------------------------------------------------
// The compareViews function is used for z-order sorting of views
// -----------------------------------------------------------------------------
NSComparisonResult compareViews(id<STUIProtocol> view1, id<STUIProtocol> view2, void * ctx) {
    return ([view1 tag] >= [view2 tag] ? NSAscendingPageOrder : NSDescendingPageOrder);
}

// -----------------------------------------------------------------------------
@implementation ChatWindowController

-(void) awakeFromNib {
    BOOL success = NO;
    NSError *error;
    
    // Attempt to find a video input device
    QTCaptureDevice *cameraDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
    QTCaptureDevice *micDevice    = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeSound];
    
    // Allocate and prepare the capture session we'll be using.
    mCaptureSession = [[QTCaptureSession alloc] init];
    
    // QTCaptureDecompressedVideoOutput will pass us raw pixel buffer data to work with for face
    // tracking and image post-processing in Core Animation.
    mCameraOutput   = [[QTCaptureDecompressedVideoOutput alloc] init];
    
    
    // Setup the pixel buffer. No need for an alpha channel so use 24-bit RGB.
    [mCameraOutput setPixelBufferAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                             [NSNumber numberWithUnsignedInt:kCVPixelFormatType_24RGB], (id)kCVPixelBufferPixelFormatTypeKey,
                                             nil]];
    // This object will be handling the callback with 
    // - (void) captureOutput:didOutputVideoFrame:withSampleBuffer:fromConnection:
    [mCameraOutput setDelegate:self];
    
    // Open the camera device
    success = [cameraDevice open:&error];
    if(!success){
        [self runAlertSheet:[error localizedDescription] withTitle:@"Could not open camera input"];
        NSLog(@"Couldn't open camera input!");
        return;
    }
    success = [micDevice open: &error];
    if(!success) {
        // If we can't open an audio input, no big deal, we won't use it.
        micDevice = nil;
    }
    // Set up recording environment
    mMovieOutput = [[QTCaptureMovieFileOutput alloc] init];
    [mCaptureSession addOutput:mMovieOutput error:nil];
    
    
    // Absolute dimensions for pixel buffer so we know how to scale.
    mPBDimensions.width = 640.0;
    mPBDimensions.height = 480.0;
    
    // Make sure the camera and PIP views are able to handle Core Animation calls
    
    [uiPIPView setParentView:uiCameraView];
    [uiCameraView setWantsLayer:YES];
    
    uiCameraLayer = uiCameraView.layer;
    //uiPIPLayer  = uiPIPView.layer;
    
    
    mCameraInput = [[QTCaptureDeviceInput alloc] initWithDevice: cameraDevice];
    
    if(micDevice) {
        // Add audio input (if we have it)
        
        mAudioInput = [[QTCaptureDeviceInput alloc] initWithDevice: micDevice];
        
        success = [mCaptureSession addInput:mAudioInput error:&error];
        if(!success) {
            [self runAlertSheet:[error localizedDescription] withTitle:@"Couldn't add audio input"];
            NSLog(@"Couldn't add audio input!");
            return;
        }
    }
    
    // Maintain aspect ratio of the window.
    [self.window setContentAspectRatio:mPBDimensions];
    
    // Add the camera input to the capture session
    success = [mCaptureSession addInput:mCameraInput error:&error];
    if(!success){
        [self runAlertSheet:[error localizedDescription] withTitle:@"Couldn't add camera input"];
        NSLog(@"Couldn't add camera input!");
        return;
    }
    
    // Add the decompressed video output
    success = [mCaptureSession addOutput:mCameraOutput error:&error];
    if(!success){
        [self runAlertSheet:[error localizedDescription] withTitle:@"Couldn't attach pixel buffer output"];
        NSLog(@"Couldn't attach pixel buffer output!");
        return;
    }
    
    // Allocate and initialize the face tracker
    mFaceTracker = [[STOCVFaceTracker alloc] init];
    [mFaceTracker setDelegate:self];
    
    mFaceOfInterest = [[STFace alloc] init];
    mFrameCount = 0;
    mSampleStride = FAST_SAMPLE_STRIDE;
    
    // Create a tracking area to watch for mouse events
    //
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:uiCameraView.bounds 
                                                  options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect) 
                                                    owner:self 
                                                 userInfo:nil];
    [uiCameraView addTrackingArea:trackingArea];
    
    [trackingArea release];
   
    mQueue = [[NSOperationQueue alloc] init];
    
    // Start the capture session asynchronously since it is a fairly lengthy operation.
    [mQueue addOperationWithBlock:^{
        [uiPlayButton setEnabled:NO];
        [mCaptureSession startRunning];
        [uiPlayButton setEnabled:YES];
    }];
    
    // Set up the video and audio compression
    
    NSEnumerator *connectionEnumerator = [[mMovieOutput connections] objectEnumerator];
    QTCaptureConnection *connection;
    
    while ((connection = [connectionEnumerator nextObject])) {
        NSString *mediaType = [connection mediaType];
        QTCompressionOptions *compressionOptions = nil;
        if ([mediaType isEqualToString:QTMediaTypeVideo]) {
            compressionOptions = [QTCompressionOptions compressionOptionsWithIdentifier:@"QTCompressionOptions240SizeMPEG4Video"];
        } else if ([mediaType isEqualToString:QTMediaTypeSound]) {
            compressionOptions = [QTCompressionOptions compressionOptionsWithIdentifier:@"QTCompressionOptionsHighQualityAACAudio"];
        }
        
        [mMovieOutput setCompressionOptions:compressionOptions forConnection:connection];
    }
        
    // Ensure the subviews are in the correct z-order.
    [uiCameraView sortSubviewsUsingFunction:compareViews context:nil];
    
    mRecording = NO;
    uiTBView.isTitleBar = YES;
    
}
// -----------------------------------------------------------------------------
-(void) dealloc{
    [mQueue release];
    [mFaceTracker release];
    [mFaceOfInterest release];
    [mCameraOutput release];
    [mCaptureSession release];
    [mCameraInput release];
    [mMovieOutput release];
    [mAudioInput release];
    [super dealloc];
}
// -----------------------------------------------------------------------------
- (void) mouseEntered:(NSEvent *)theEvent{
    [uiBBView setHidden:NO];
    [uiTBView setHidden:NO];
}
// -----------------------------------------------------------------------------
- (void) mouseExited:(NSEvent *)theEvent {
    [uiBBView setHidden:YES];
    [uiTBView setHidden:YES];
}
// -----------------------------------------------------------------------------
- (void) runAlertSheet: (NSString*) alertMessage withTitle: (NSString*) alertTitle{
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:alertTitle];
    [alert setInformativeText:alertMessage];
    [alert setAlertStyle: NSWarningAlertStyle];
    [alert beginSheetModalForWindow:self.window modalDelegate:self 
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    
    
}
// -----------------------------------------------------------------------------
- (void) alertDidEnd: (NSAlert*) alert returnCode: (int) returnCode contextInfo: (void*) contextInfo{
    [alert release];
}
// -----------------------------------------------------------------------------
-(void) updateCameraLayer:(CGImageWrapper*) image{
    
    [uiPIPView setCurrentFrame:image.image]; 
    [uiCameraLayer setContents:(id)image.image];  
    
    [image release];
}

// -----------------------------------------------------------------------------
// captureOutput is called whenever the pixel buffer is updated from QTCapture
// -----------------------------------------------------------------------------
- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame 
     withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection
{
    
    mFrameCount++;
    CVPixelBufferLockBaseAddress((CVPixelBufferRef)videoFrame, 0);
    
    
    // Call the face tracker and attempt to update the face positions; positions will only be updated
    // if there is not an update operation presently occurring.
    // Don't bother updating if uiPIPView is being dragged around.    
    if(!(mFrameCount%mSampleStride) && !uiPIPView.dragging)    [mFaceTracker updateFacePositions:videoFrame];
    
    
    // The captureOutput: selector is not called on the main thread, so in order to get the image back to the main thread for
    // display, we must wrap it in an object.
    [self performSelectorOnMainThread:@selector(updateCameraLayer:)
                           withObject:[[CGImageWrapper alloc] initWithCVImageBufferRef:videoFrame] 
                        waitUntilDone:YES
     ];
    
    CVPixelBufferUnlockBaseAddress((CVPixelBufferRef)videoFrame, 0);
    
}

// -----------------------------------------------------------------------------
// gotUpdatedFacePositions is a callback from OCVFaceTracker that is called whenever the location of faces
// is updated.
// -----------------------------------------------------------------------------
- (void) gotUpdatedFacePositions: (NSArray*) locations{
    
    if([locations count] > 0){
        
        // Just using one face of interest right now.  
        
        [mFaceOfInterest updatePosition:[[locations objectAtIndex:0] rectValue]];  // Update its position and recompute its speed.
        
        if( mFaceOfInterest.speed < SPEED_CUTOFF ){
            // Speed is low enough to consider the movement intentional or stationary
            
            double cx,cy,cr,scale,d,w;
            BOOL swapBox = NO;
            
            mSampleStride = SLOW_SAMPLE_STRIDE; // If the user isn't moving very quickly, slow down the sample time to save on CPU.
            
            NSRect r = uiPIPView.frame;
            
            hit_box_t hb = mFaceOfInterest.hitBox;
            
            // Since the pixel buffer and the actual NSView sizes are (probably) different,
            // we need to scale the hit box accordingly.
            
            scale = (uiCameraView.bounds.size.height / mPBDimensions.height);
            
            w = uiCameraView.bounds.size.width / 2.0;
            d = fabs(hb.x * scale - w);
            
            // If the face is too close to the center of the screen, don't bother moving the PIP view
            // as it may cause the PIP view to bounce back and forth.
            if( d < w *  DISTANCE_CUTOFF)
                return;
            
            cy = floor((mPBDimensions.height - hb.y) * scale);   // the hitbox co-ordinates are top-left origin, CoreAnimation is bottom-left
            cx = floor(hb.x * scale);
            cr = floor(hb.r * scale); 
            
            // Test to see if any of the corners of the PIP view have encountered the face.
            //  - This needs to be changed to test the area of the rectangle against the area
            //    of the circle.
            
            if (hit_test(cx,cy,cr,(r.origin.x+r.size.width), (r.origin.y+r.size.height)) || // Top right
                hit_test(cx,cy,cr, r.origin.x,               (r.origin.y+r.size.height)) || // Top left
                hit_test(cx,cy,cr,(r.origin.x+r.size.width),  r.origin.y)                || // Bottom right
                hit_test(cx,cy,cr, r.origin.x,                r.origin.y))                  // Bottom left
            {
                swapBox = YES;
            }
            
            if(swapBox){
                // Swap the origin x
                r.origin.x = (uiCameraView.bounds.size.width - r.origin.x - r.size.width);
                [uiPIPView setFrameOrigin: r.origin];
                
            }
            
            
        } else {
            mSampleStride = FAST_SAMPLE_STRIDE;
            
        }
    }
}

// -----------------------------------------------------------------------------
// Button Actions
// -----------------------------------------------------------------------------

- (IBAction) playButtonClick: (id) sender {
    
    if(mCaptureSession.isRunning){
        // Pause playback
        
        if(mRecording) // If we're recording stop the recording first and reset the button
            [self recordButtonClick:nil];
        
        [mQueue addOperationWithBlock:^{
            [mCaptureSession stopRunning];
        }];
        
        [uiRecordButton setEnabled:NO];
        [uiPlayButton setImage:[NSImage imageNamed:@"control_start.png"]];
    }
    else {
        // Restart playback
        [mQueue addOperationWithBlock:^{
            [uiPlayButton setEnabled:NO];
            [mCaptureSession startRunning];
            [uiPlayButton setEnabled:YES];
        }];
        [uiPlayButton setImage:[NSImage imageNamed:@"control_pause.png"]];
        [uiRecordButton setEnabled:YES];
    }
}
// -----------------------------------------------------------------------------

- (IBAction) recordButtonClick: (id) sender {
    
    if(mCaptureSession.isRunning) {
        // Only start recording if we have a started session
        CIFilter * f = [CIFilter filterWithName:@"CIColorMonochrome"];
        
        if(!mRecording){
            [f setValue:[CIColor colorWithCGColor:CGColorCreateGenericRGB(0, 0.83, 0.02, 1.0)] forKey:@"inputColor"];
            [mMovieOutput recordToOutputFileURL:[NSURL fileURLWithPath:@"/Users/Shared/webcamMovie.mov"]];
            [uiRecordButton setImage:[NSImage imageNamed:@"control_stop.png"]];
        }
        else {
            [f setValue:[CIColor colorWithCGColor:CGColorCreateGenericRGB(0.83, 0.0, 0.02, 1.0)] forKey:@"inputColor"];
            [mMovieOutput recordToOutputFileURL:nil];
            [uiRecordButton setImage:[NSImage imageNamed:@"control_record.png"]];
        }
        
        [f setValue:[NSNumber numberWithFloat:1.0] forKey: @"inputIntensity"];
        NSArray* filters = [[NSArray alloc] initWithObjects:f, nil];
        
        [uiRecordButton setContentFilters:filters];
        [filters release];
        
        mRecording ^= 1;
    }
}
// -----------------------------------------------------------------------------
@end
