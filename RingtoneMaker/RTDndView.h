//
//  RTDndView.h
//  RingtoneMaker
//
//  Created by Valeriy Chevtaev on 12/29/11.
//  Copyright (c) 2011 7bit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RTDndView : NSView<NSDraggingDestination>
{
@private
    NSString * tempFilePath_;
    BOOL draggingInProgress_;
}

- (void) appWillClose;
- (void) cleanupCurrentAudio;

@end
