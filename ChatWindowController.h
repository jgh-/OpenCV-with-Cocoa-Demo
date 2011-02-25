/*  
 *  Webcam/FaceTracking/Custom Views example project - jamesghurley<at>gmail.com
 *  This project emulates 1-on-1 video conferencing using modern Cocoa frameworks and techniques.
 *  
 *  ChatWindowController.h/.m - Manages a "video chat" instance.
 */
#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <QuartzCore/QuartzCore.h>
#import "STOCVFaceTracker.h"


@class STFace;
@class STPictureInPictureView;
@class STButton;
@class STButtonBarView;


@interface ChatWindowController : NSWindowController<STOCVFaceTrackerProtocol> {

    QTCaptureSession                 *mCaptureSession;
    QTCaptureMovieFileOutput         *mMovieOutput   ; // For saving captured video
    QTCaptureDeviceInput             *mCameraInput   ; // Webcam device input
    QTCaptureDeviceInput             *mAudioInput    ;
    
    QTCaptureDecompressedVideoOutput *mCameraOutput  ; // Source we'll be using to grab
                                                       // pixel buffer data
    
    NSOperationQueue                 *mQueue         ; // Send lengthy operations to GCD
    STOCVFaceTracker                 *mFaceTracker   ;
    STFace                           *mFaceOfInterest; // Only going to track one face at a time right now.
      
    NSSize                            mPBDimensions  ;
    
    short                             mSampleStride  ;
    long                              mFrameCount    ;
    BOOL                              mRecording     ;
    
    IBOutlet NSView                  *uiCameraView   ; // Main camera view
    IBOutlet STPictureInPictureView  *uiPIPView      ; // Picture-in-Picture view
    IBOutlet STButtonBarView         *uiBBView       ; // Bottom button bar
    IBOutlet STButtonBarView         *uiTBView       ; // Top bar with close button
    
    IBOutlet STButton                *uiPlayButton   ; // Play/pause PIP content
    IBOutlet STButton                *uiRecordButton ;
    
    CALayer                          *uiCameraLayer  , // Drawing layers
                                     *uiPIPLayer     ; // for Core Animation
    
}
- (IBAction) playButtonClick:   (id) sender;
- (IBAction) recordButtonClick: (id) sender;
@end
