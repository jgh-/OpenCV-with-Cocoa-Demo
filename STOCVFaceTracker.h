/*  
 *  Webcam/FaceTracking/Custom Views example project - jamesghurley<at>gmail.com
 *  This project emulates 1-on-1 video conferencing using modern Cocoa frameworks and techniques.
 *  
 *  OCVFaceTracker.h/.m - OpenCV Face Tracking implemented in Cocoa.
 *  This is a Cocoa/CoreVideo implementation based on the OpenCV FaceTracker.cpp example.
 */

#import <Cocoa/Cocoa.h>
#import <cv.h>
#import <CoreVideo/CoreVideo.h>


@protocol STOCVFaceTrackerProtocol

@required

- (void) gotUpdatedFacePositions: (NSArray*) locations;

@end

@interface STOCVFaceTracker : NSObject {

    CvHaarClassifierCascade     *mCascade           ;
    CvMemStorage                *mStorage           ;
    
    id<STOCVFaceTrackerProtocol>  delegate          ;
    
    IplImage                    *mCurrentImage      ;
    uint8_t                     *mCurrentImageData  ;
    BOOL                         mCanUpdateFaces    ;
    NSBitmapImageRep            *mCurrentBitmap     ;
    
    NSOperationQueue            *mQueue             ;
    NSArray                     *mCurrentFaces      ;

}
@property (assign)  id<STOCVFaceTrackerProtocol> delegate;
- (void) updateFacePositions: (CVPixelBufferRef) image;
@end
