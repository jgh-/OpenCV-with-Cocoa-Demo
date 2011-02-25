//
/*  
 *  Webcam/FaceTracking/Custom Views example project - jamesghurley<at>gmail.com
 *  This project emulates 1-on-1 video conferencing using modern Cocoa frameworks and techniques.
 *  
 *  STFace.h/.m - Track a face's movement.
 */

#import "STFace.h"

#define W  0.75 // W is the ratio between mWeights[i] and mWeights[i+1].  This will always result in a set that sums to
                // 1, but it will affect the shape of the curve (a lower W constant will yield a curve with a sharper dropoff).
                // A flatter curve will require a longer time for speed changes to affect the overall weighted mean.

@implementation STFace
@synthesize rect,speed,hitBox;
// -----------------------------------------------------------------------------
- (id) init {
    
    double  v;
    int     i;
    
    if((self = [super init])){
        mWeightedSamples = [[NSMutableArray alloc] initWithCapacity:1];
        rect = NSMakeRect(0.0, 0.0, 0.0, 0.0);
        speed = 0.0;      
        
        // Generate normalized weighting values for weighted mean.
        v = (1.0 - pow(W, SAMPLE_COUNT)) / (1.0 - W);
        for ( i = 0 ; i < SAMPLE_COUNT; i ++ ){
            mWeights[i] = pow(W, i) / v;
        }
        
    }
    return self;
}
// -----------------------------------------------------------------------------
- (void) dealloc{
    [mWeightedSamples release];
    [super dealloc];
}
// -----------------------------------------------------------------------------
- (void) computeWeightedMean{
    
    // Right now this is just tracking the face's speed and assuming that
    // a low speed equates to an intentional movement, or the user is in a stationary
    // position.
    // It may be more accurate to generate velocity vectors to decide if the user will be
    // encountering the bounding box, or if they're on their way out of the box, for example.
    
    int i ;
    speed = 0.0;
        

    for ( i = 0; i < [mWeightedSamples count]; i ++ ){
        speed += [[mWeightedSamples objectAtIndex:i] doubleValue] * mWeights[i];
        
    }
   
}
// -----------------------------------------------------------------------------
- (void) updatePosition: (NSRect) newPosition{
    
    double d = sqrt(pow(newPosition.origin.x - rect.origin.x, 2) +
                    pow(newPosition.origin.y - rect.origin.y, 2));
    
    rect = newPosition;
    
    hitBox.y = rect.origin.y + rect.size.height*0.5;
    
    hitBox.x = rect.origin.x + rect.size.width*0.5;
    
    hitBox.r = (rect.size.width < rect.size.height ? rect.size.width : rect.size.height) * 0.5;
    
    [mWeightedSamples insertObject:[NSNumber numberWithDouble:d] atIndex:0];
    
    if([mWeightedSamples count] > SAMPLE_COUNT)
        [mWeightedSamples removeLastObject];
    
    [self computeWeightedMean];
}
// -----------------------------------------------------------------------------
@end
