//
//  RTImageView.h
//  RingtoneMaker
//
//  Created by Valeriy Chevtaev on 12/30/11.
//  Copyright (c) 2011 7bit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#define RTPasteBoardName @"RTPasteBoard"

@interface RTImageView : NSImageView<NSDraggingSource>
{
@private
    //props
    NSURL * _fileUrl;
}

@property (strong) NSURL * fileUrl;

- (void) mouseDown:(NSEvent*)event;
- (BOOL) acceptsFirstMouse:(NSEvent *)event;

@end
