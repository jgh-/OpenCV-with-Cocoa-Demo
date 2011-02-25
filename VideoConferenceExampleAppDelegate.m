/*  
 *  Webcam/FaceTracking/Custom Views example project - jamesghurley<at>gmail.com
 *  This project emulates 1-on-1 video conferencing using modern Cocoa frameworks and techniques.
 *  
 *  VideoConferenceExampleAppDelegate.h/.m - Manages the main menu and chat windows.
 */

#import "VideoConferenceExampleAppDelegate.h"
#import "ChatWindowController.h"

@implementation VideoConferenceExampleAppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
    uiCWControllers = [[NSMutableArray alloc] initWithCapacity:1];
    ChatWindowController * cwControl = [[ChatWindowController alloc] initWithWindowNibName:@"ChatWindow"];
    [cwControl showWindow:nil];
    [uiCWControllers addObject:cwControl];
}
// -----------------------------------------------------------------------------
- (void) dealloc{
    [uiCWControllers release];
    [super dealloc];
}
@end
