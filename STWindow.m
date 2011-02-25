/*  
 *  Webcam/FaceTracking/Custom Views example project - jamesghurley<at>gmail.com
 *  This project emulates 1-on-1 video conferencing using modern Cocoa frameworks and techniques.
 *  
 *  STWindow.h/.m - Borderless window.
 */
#import "STWindow.h"


@implementation STWindow
- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)windowStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)deferCreation
{
    self = [super
            initWithContentRect:contentRect
            styleMask:NSBorderlessWindowMask
            backing:bufferingType
            defer:deferCreation];
	if (self)
	{
		[self setOpaque:NO];
		[self setBackgroundColor:[NSColor whiteColor]];
        
		[[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(mainWindowChanged:)
         name:NSWindowDidBecomeMainNotification
         object:self];
		
		[[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(mainWindowChanged:)
         name:NSWindowDidResignMainNotification
         object:self];
    }        
    return self;
}
// -----------------------------------------------------------------------------
- (void)mainWindowChanged:(NSNotification *)aNotification
{

}
// -----------------------------------------------------------------------------
-(void) awakeFromNib{
}
// -----------------------------------------------------------------------------
- (BOOL)canBecomeKeyWindow {
	return YES;
}
@end
