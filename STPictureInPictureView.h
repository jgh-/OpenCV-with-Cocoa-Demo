//
//  PIPView.h
//  VideoConferenceExample
//
//  Created by James Hurley on 10-10-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@interface STPictureInPictureView : QTMovieView {
    
    NSPoint         mLastDragLocation;
    NSView         *parentView       ;
    
    QTMovie        *mMovie           ;
    BOOL            mResizing        ;
    
    BOOL            dragging         ;
    int             tag              ;
    
}
@property (readonly) BOOL dragging;
@property (assign) NSView *parentView;
@property (readwrite) int tag;

- (void) setCurrentFrame: (CGImageRef) image;


@end
