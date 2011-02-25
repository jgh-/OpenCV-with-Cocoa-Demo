//
//  STButton.m
//  VideoConferenceExample
//
//  Created by James Hurley on 10-10-13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "STButton.h"

static int s_buTag = 100;

@implementation STButton
@synthesize tag;
// -----------------------------------------------------------------------------
- (id) init {
    if(self = [super init]){
        tag = s_buTag++;
    }
    return self;
}


@end
