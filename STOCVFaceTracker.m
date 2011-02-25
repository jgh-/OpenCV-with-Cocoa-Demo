/*  
 *  Webcam/FaceTracking/Custom Views example project - jamesghurley<at>gmail.com
 *  This project emulates 1-on-1 video conferencing using modern Cocoa frameworks and techniques.
 *  
 *  OCVFaceTracker.h/.m - OpenCV Face Tracking implemented in Cocoa.
 *  This is a Cocoa/CoreVideo implementation based on the OpenCV FaceTracker.cpp example.
 */

#import "STOCVFaceTracker.h"

#import "CGImageWrapper.h"

#define HAAR_CASCADE_SRC    @"haarcascade_frontalface_alt2"

// -----------------------------------------------------------------------------
// STOCVFaceTracker Private Methods
// -----------------------------------------------------------------------------
@interface STOCVFaceTracker (Private)

- (void) didFinishFaceDetectionWithPositions: (NSArray*) facePositions;

@end
// -----------------------------------------------------------------------------
@implementation STOCVFaceTracker
@synthesize delegate;
// -----------------------------------------------------------------------------
- (id) init{
    if((self = [super init])){
        mCanUpdateFaces = YES;
        mQueue = [[NSOperationQueue alloc] init];
        mCurrentFaces = [[NSArray alloc] init];
        
        // Load the Haar-like feature cascade.
        mCascade = (CvHaarClassifierCascade*) cvLoad(
                                [[[NSBundle mainBundle] pathForResource:HAAR_CASCADE_SRC ofType:@"xml"] UTF8String],
                                 0, 0, 0);
        mStorage = cvCreateMemStorage(0);
    }
    return self;
}
// -----------------------------------------------------------------------------
- (void) dealloc{
    cvClearMemStorage(mStorage);
    [mQueue release];
    if(mCurrentFaces != nil) 
        [mCurrentFaces release];
    cvFree_(mCascade);
    if(mCurrentImage){
        free(mCurrentImage);
        mCurrentImage = 0;
    }
    if(mCurrentImageData) {
        free(mCurrentImageData);
        mCurrentImageData = 0;
    }
    
    [super dealloc];
}
// -----------------------------------------------------------------------------
- (void) didFinishFaceDetectionWithPositions: (NSArray*) facePositions{
    
    
    if(mCurrentFaces != nil) 
        [mCurrentFaces release];
    if(mCurrentImage){
        free(mCurrentImage);
        mCurrentImage = 0;
    }
    if(mCurrentImageData) {
        free(mCurrentImageData);
        mCurrentImageData = 0;
    }
    
    mCurrentFaces = [[NSArray alloc] initWithArray: facePositions];
    
    [facePositions release];
    
    [delegate gotUpdatedFacePositions:mCurrentFaces];
    
    mCanUpdateFaces = YES;
    
}
// -----------------------------------------------------------------------------

- (void) updateFacePositions: (CVPixelBufferRef) image{
    // This is a potentially slow operation so we're going to check to see
    // if we're able to update the faces, and then throw it to GCD to asynchronously do the
    // face detection.
    long dataSize;
    if(mCanUpdateFaces){
        
        
        dataSize = CVPixelBufferGetDataSize(image);
        mCurrentImage = calloc(1,sizeof(IplImage));
        
        if(!mCurrentImage) return;
        
        mCurrentImageData = malloc(dataSize);
        
        if(!mCurrentImageData) {
            free(mCurrentImage);
            return;
        }
        
        mCanUpdateFaces = NO;
        memcpy(mCurrentImageData, CVPixelBufferGetBaseAddress(image), dataSize);
        
        mCurrentImage->nSize            = sizeof(IplImage);
        mCurrentImage->nChannels        = 3;
        mCurrentImage->depth            = IPL_DEPTH_8U;
        mCurrentImage->width            = CVPixelBufferGetWidth(image);
        mCurrentImage->height           = CVPixelBufferGetHeight(image);
        mCurrentImage->roi              = 0;                   // Could use a Region of Interest based on the previous frame
        mCurrentImage->imageSize        = dataSize;
        mCurrentImage->imageData        = (char*)mCurrentImageData;
        mCurrentImage->imageDataOrigin  = mCurrentImage->imageData;
        mCurrentImage->widthStep        = CVPixelBufferGetBytesPerRow(image);
        
        
        [mQueue addOperationWithBlock:^{
            
            // Asynchronously perform face detection in this block.
            
            int scale = 2;
            NSMutableArray * faces = [[NSMutableArray alloc] initWithCapacity:1];
            IplImage *  gray_image    = cvCreateImage(cvSize (mCurrentImage->width, mCurrentImage->height), IPL_DEPTH_8U, 1);
            IplImage *  small_image   = cvCreateImage(cvSize(mCurrentImage->width / scale, mCurrentImage->height / scale), IPL_DEPTH_8U, 1);
            cvCvtColor (mCurrentImage, gray_image, CV_BGR2GRAY);
            cvResize(gray_image, small_image, CV_INTER_LINEAR);
 
            
                        
            // Fast(ish) face detection based on parameters recommended at 
            // http://www.emgu.com/wiki/files/1.3.0.0/html/55a16889-537c-534f-f2fa-fbbe60e1d8d4.htm
            
            CvSeq* cfaces = cvHaarDetectObjects(small_image, mCascade, mStorage, 
                                                1.2, 2, CV_HAAR_DO_CANNY_PRUNING, 
                                                cvSize(mCurrentImage->width/scale*0.25,mCurrentImage->height/scale*0.25));
            
            cvReleaseImage(&gray_image);
            cvReleaseImage(&small_image);
            
            // Create an NSRect for each face found and add it to the array.
            for (int i = 0 ; i < (!!cfaces ? cfaces->total : 0); i++){
                CvRect* r = (CvRect*) cvGetSeqElem (cfaces, i);
                [faces addObject:[NSValue valueWithRect:NSMakeRect(r->x * scale, r->y * scale, r->width * scale, r->height * scale)]];
               
            } 
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                // Call back to the main thread with the list of faces
                [self didFinishFaceDetectionWithPositions:faces];
            }];
        }];
    }
}
// -----------------------------------------------------------------------------
@end
