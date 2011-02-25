/*  
 *  Webcam/FaceTracking/Custom Views example project - jamesghurley<at>gmail.com
 *  This project emulates 1-on-1 video conferencing using modern Cocoa frameworks and techniques.
 *  
 *  STPictureInPictureView.h/.m - Picture-In-Picture custom view.
 */

#import "STPictureInPictureView.h"
#import <Quartz/Quartz.h>

@implementation STPictureInPictureView
@synthesize parentView, tag, dragging;

// -----------------------------------------------------------------------------
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        tag = 1;
    }
    return self;
}

// -----------------------------------------------------------------------------
- (void) awakeFromNib {
    NSError *error;
    
    
    //mMovie = [QTMovie movieNamed:@"mars.mp4" error:&error];

    //[mMovie autoplay];
    
    //[self setMovie:mMovie];
    [self setControllerVisible: NO];

   
}
// -----------------------------------------------------------------------------
- (void) dealloc{
    [super dealloc];
}
// -----------------------------------------------------------------------------
- (BOOL)  preservesContentDuringLiveResize{
    return NO;
}
// -----------------------------------------------------------------------------
- (void) setCurrentFrame: (CGImageRef) image{
    [self.layer setContents:(id)image];
    
}
// -----------------------------------------------------------------------------
- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
    
    [self.layer setBorderColor:CGColorCreateGenericRGB(0.2, 0.2, 0.2, 0.5)];
    [self.layer setBorderWidth:1.f];
    NSShadow * shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowBlurRadius:2.f];
    [shadow setShadowOffset:NSMakeSize(0,0)];
    [self setShadow:shadow];
    
    [shadow release];
    
}
// -----------------------------------------------------------------------------
// Mouse dragging code
- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}
// -----------------------------------------------------------------------------
- (void)mouseDown:(NSEvent *)theEvent {
	mLastDragLocation = [theEvent locationInWindow]; 
    mResizing = NO;
    if((mLastDragLocation.x >= (self.frame.origin.x + self.frame.size.width - 16))
        && (mLastDragLocation.y >= (self.frame.origin.y + self.frame.size.height - 16)))
        mResizing = YES;
    
    dragging = YES;
}
// -----------------------------------------------------------------------------
- (void)mouseDragged:(NSEvent *)theEvent {
    NSPoint newDragLocation = [theEvent locationInWindow];
	NSPoint thisOrigin = [self frame].origin;
    NSSize  thisSize   = [self frame].size;
    if(!mResizing) {
        // Drag window
        thisOrigin.x += (-mLastDragLocation.x + newDragLocation.x);
        thisOrigin.y += (-mLastDragLocation.y + newDragLocation.y);
        [self setFrameOrigin:thisOrigin];
	} else {
        // Resize window
        double aspect = thisSize.height / thisSize.width;
        
        thisSize.width += (-mLastDragLocation.x + newDragLocation.x);
        thisSize.height = thisSize.width*aspect;
        [self setFrameSize:thisSize];
    }

    mLastDragLocation = newDragLocation;
    
}
- (void) mouseUp:(NSEvent*) theEvent{
    dragging = NO;
}
// -----------------------------------------------------------------------------
- (void)setFrameOrigin: (NSPoint) newOrigin {
    
    [super setFrameOrigin:newOrigin];    
    
    double w = parentView.bounds.size.width / 2.0;
    double h = parentView.bounds.size.height / 2.0;
    
    // Because we've moved the view around, the autosizing mask (probably) doesn't work properly anymore,
    // so we need to make a new mask based on the quadrant the view finds itself in.
    if(newOrigin.x >= w && newOrigin.y >= h){
        // Top right
        [self setAutoresizingMask:(NSViewMinXMargin | NSViewMinYMargin | NSViewWidthSizable | NSViewHeightSizable)];
    }
    else if(newOrigin.x >= w && newOrigin.y < h){
        // Bottom right
        [self setAutoresizingMask:(NSViewMinXMargin | NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable)];
    }
    else if(newOrigin.x < w && newOrigin.y >= h){
        // bottom left
        [self setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin | NSViewWidthSizable | NSViewHeightSizable)];
    } else {
        // Top left
        [self setAutoresizingMask:(NSViewMaxXMargin | NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable)];
    }
    
}
// -----------------------------------------------------------------------------
@end
