/*  
 *  Webcam/FaceTracking/Custom Views example project - jamesghurley<at>gmail.com
 *  This project emulates 1-on-1 video conferencing using modern Cocoa frameworks and techniques.
 *  
 *  STButtonBarView.h/.m - View used for the top and bottom bars in the app.
 */

#import <Cocoa/Cocoa.h>


@class STWindow;

@interface STButtonBarView : NSView {
    BOOL        hidden ;
    int         tag    ; 
    BOOL        isTitleBar;
    BOOL        mResizing;
    NSPoint     mLastDragLocation;
}
@property (readonly)  BOOL      hidden;
@property (readwrite) int       tag;
@property (assign)    BOOL      isTitleBar;


- (void) setHidden:(BOOL) isHidden ;

@end
