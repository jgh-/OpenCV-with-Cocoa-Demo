/*  
 *  Webcam/FaceTracking/Custom Views example project - jamesghurley<at>gmail.com
 *  This project emulates 1-on-1 video conferencing using modern Cocoa frameworks and techniques.
 *  
 *  STFace.h/.m - Track a face's movement.
 */

#import <Cocoa/Cocoa.h>

#define SAMPLE_COUNT    20

typedef struct {
    double x, y, r;
} hit_box_t;

@interface STFace : NSObject {
    
    NSRect          rect                    ;
    double          speed                   ;  // In the future this should be changed to a vector
    hit_box_t       hitBox                  ;
    
    double          mWeights[SAMPLE_COUNT]  ;
    NSMutableArray *mWeightedSamples        ;
    
}
@property (readonly) NSRect     rect;
@property (readonly) double     speed;
@property (readonly) hit_box_t  hitBox;

- (void) updatePosition: (NSRect) newPosition;
@end
