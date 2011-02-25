/*  
 *  Webcam/FaceTracking/Custom Views example project - jamesghurley<at>gmail.com
 *  This project emulates 1-on-1 video conferencing using modern Cocoa frameworks and techniques.
 *  
 *  STButtonBarView.h/.m - View used for the top and bottom bars in the app.
 */

#import "STButtonBarView.h"
#import <Quartz/Quartz.h>
#import "STWindow.h"

static int  s_bbTag = 10  ; 

@implementation STButtonBarView
@synthesize hidden, tag, isTitleBar;

// -----------------------------------------------------------------------------
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        // Set up the background gradients
        CGColorRef gradient[] = {
            CGColorCreateGenericRGB(37.0/255.0, 45.0/255.0, 56.0/255.0,1.0),
            CGColorCreateGenericRGB(72.0/255.0, 94.0/255.0, 120.0/255.0,0.8)
        };
        NSArray *colors;
        if(self.frame.origin.y == 0) // Bottom bar
            colors = [NSArray arrayWithObjects:(id) gradient[0], (id) gradient[1], nil];
        else                         // Top bar
            colors = [NSArray arrayWithObjects:(id) gradient[1], (id) gradient[0], nil];
        

        for (int i = 0 ; i < 2 ; i ++) CFRelease(gradient[i]);
        
        CAGradientLayer * layer = [[CAGradientLayer layer] retain];
        [layer setColors:colors];
        [self setLayer:layer];
     
        [layer release];
        
        tag = s_bbTag++; // Tag is used for view z-order sorting.
        isTitleBar = NO;
    }
    return self;
}
// -----------------------------------------------------------------------------
- (void) awakeFromNib{
    // Make sure we can use Core Animation
    [self setWantsLayer:YES];
    // Give the bars a little drop shadow
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset:NSMakeSize(0.0,(self.frame.origin.y == 0 ? 1.0 : -1.0))];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowBlurRadius:3.f];
    [self setShadow:shadow];
    
    [shadow release];
    // Set the views to transparent initially
    [self setAlphaValue:0.0];
    hidden = YES;
}

// -----------------------------------------------------------------------------
- (void) setHidden:(BOOL) isHidden {
    
    // Animated transition from transparent to opaque when the mouse enters
    // the window
    if(!isHidden){
        [[self animator] setAlphaValue: 1.0];
    
    } else {
        [[self animator] setAlphaValue: 0.0];
    }
    hidden = isHidden;
}
// -----------------------------------------------------------------------------
- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
    
}
// -----------------------------------------------------------------------------
- (void)mouseDown:(NSEvent *)theEvent {
   	
    NSWindow *window = [self window];
    if(isTitleBar && window) {
        // If they're clicking down on the title bar, it's a drag event
        mLastDragLocation = [window convertBaseToScreen:[theEvent locationInWindow]]; 
    }
    else if(!isTitleBar && window) {
        // Clicking in the bottom bar, could be resizing.
        mResizing = NO;
        mLastDragLocation = [window convertBaseToScreen:[theEvent locationInWindow]];
        if([theEvent locationInWindow].x >= [window frame].size.width - 16 && [theEvent locationInWindow].y <= 16)
            mResizing = YES;
    }
}
// -----------------------------------------------------------------------------
- (void)mouseDragged:(NSEvent *)theEvent {
    
    NSWindow *window = [self window];
    NSPoint newDragLocation = [window convertBaseToScreen:[theEvent locationInWindow]];
    NSRect frame = window.frame;
    
    if(isTitleBar && window) {
        // Dragging the window around

        frame.origin.x += (-mLastDragLocation.x + newDragLocation.x);
        frame.origin.y += (-mLastDragLocation.y + newDragLocation.y);
        
        mLastDragLocation = newDragLocation;
    }
    else if(!isTitleBar && window && mResizing) {
        // Resizing the window; obey aspect ratio.
        double x1 = mLastDragLocation.x, x2 = newDragLocation.x;
        double aspect = [window contentAspectRatio].height / [window contentAspectRatio].width;
        frame.size.width += (-x1 + x2);
        frame.size.height = frame.size.width * aspect;
        frame.origin.y += ([window frame].size.height - frame.size.height);
   
        mLastDragLocation = newDragLocation;
    }
    [window setFrame:frame display:YES animate:NO];
}

@end
