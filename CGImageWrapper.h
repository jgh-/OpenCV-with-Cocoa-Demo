/*  
 *  Webcam/FaceTracking/Custom Views example project - jamesghurley<at>gmail.com
 *  This project emulates 1-on-1 video conferencing using modern Cocoa frameworks and techniques.
 *  
 *  CGImageWrapper.h/.m - Used to pass a CGImageRef to the main thread.
 */

#import <Cocoa/Cocoa.h>


@interface CGImageWrapper : NSObject {
    @public
    CGImageRef image;
}
@property CGImageRef image;

-(id) initWithCGImage: (CGImageRef) _image;
-(id) initWithCVImageBufferRef: (CVImageBufferRef) _imageBuffer;
@end
