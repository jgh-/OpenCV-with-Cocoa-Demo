//
//  STButton.h
//  VideoConferenceExample
//
//  Created by James Hurley on 10-10-13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface STButton : NSButton {
    int  tag;
}
@property (readonly) int tag;
@end
