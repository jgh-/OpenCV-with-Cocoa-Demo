/*  
 *  Webcam/FaceTracking/Custom Views example project - jamesghurley<at>gmail.com
 *  This project emulates 1-on-1 video conferencing using modern Cocoa frameworks and techniques.
 *  
 *  CGImageWrapper.h/.m - Used to pass a CGImageRef to the main thread.
 */
#import "CGImageWrapper.h"
#import <CoreVideo/CoreVideo.h>


@implementation CGImageWrapper
@synthesize image;
// -----------------------------------------------------------------------------
- (id) initWithCGImage:(CGImageRef)_image{
    if((self = [super init])){
        image = _image;
    }
    return self;
}
// -----------------------------------------------------------------------------
-(id) initWithCVImageBufferRef: (CVImageBufferRef) _imageBuffer{
    
    if((self = [super init])){
        
        CGColorSpaceRef  colorSpace  = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        void            *baseAddr    = CVPixelBufferGetBaseAddress(_imageBuffer);
        size_t           bytesPerRow = CVPixelBufferGetBytesPerRow(_imageBuffer);
        size_t           width       = CVPixelBufferGetWidth(_imageBuffer);
        size_t           height      = CVPixelBufferGetHeight(_imageBuffer);
    
        CGDataProviderRef provider   = CGDataProviderCreateWithData(NULL, baseAddr, bytesPerRow*height, NULL);
    
        image = CGImageCreate(width, height, 8, 24, bytesPerRow, colorSpace, kCGImageAlphaNone, provider, NULL, false, kCGRenderingIntentDefault);
        
        CGColorSpaceRelease(colorSpace);
        CGDataProviderRelease(provider);
    }
    
    return self;
}
// -----------------------------------------------------------------------------
- (void) dealloc{
    CGImageRelease(image);
    [super dealloc];
}
@end
