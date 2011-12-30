//
//  RTImageView.m
//  RingtoneMaker
//
//  Created by Valeriy Chevtaev on 12/30/11.
//  Copyright (c) 2011 7bit. All rights reserved.
//

#import "RTImageView.h"
#import "RTLog.h"

@implementation RTImageView

@synthesize fileUrl = _fileUrl;


#pragma mark - Dragging

- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    RTLog(@"RTImageView - dragging endedAtPoint");
}

- (void)draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint
{
    RTLog(@"RTImageView - dragging willBeginAtPoint");
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    RTLog(@"RTImageView - dragging started");
    
    switch (context) {
        case NSDraggingContextOutsideApplication:
            RTLog(@"RTImageView - drag outside the application");
            return NSDragOperationAll;
            break;
            
        case NSDraggingContextWithinApplication:
            RTLog(@"RTImageView - drag within the application");
            return NSDragOperationNone;
            break;
            
        default:
            RTLog(@"RTImageView - drag default");
            return NSDragOperationNone;
            break;
    }
}

- (void) mouseDown:(NSEvent*)event
{
    RTLog(@"RTImageView - mouseDown");
    
    NSPoint tvarMouseInWindow = [event locationInWindow];
    NSPoint tvarMouseInView = [self convertPoint:tvarMouseInWindow fromView:nil];
    
    NSSize zDragOffset = NSMakeSize(0.0, 0.0);
    NSPasteboard *zPasteBoard;
    
    zPasteBoard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [zPasteBoard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];  //NSSoundPboardType
    [zPasteBoard setPropertyList:[NSArray arrayWithObject:[self.fileUrl path]] forType:NSFilenamesPboardType];
    
    [self dragImage:self.image 
                 at:tvarMouseInView 
             offset:zDragOffset
              event:event 
         pasteboard:zPasteBoard 
             source:self 
          slideBack:YES];
    
    
//    NSPasteboardItem *pbItem = [NSPasteboardItem new];
//    [pbItem setDataProvider:self forTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
//    
//    NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
//    [pbItem release];
//    
//    NSRect draggingRect = self.bounds;
//    [dragItem setDraggingFrame:draggingRect contents:[self image]];
//    
//    NSDraggingSession *draggingSession = [self beginDraggingSessionWithItems:[NSArray arrayWithObject:[dragItem autorelease]] event:event source:self];
//    
//    draggingSession.animatesToStartingPositionsOnCancelOrFail = YES;
//    draggingSession.draggingFormation = NSDraggingFormationDefault;
    
}

- (BOOL) acceptsFirstMouse:(NSEvent *)event 
{
    //so source doesn't have to be the active window
    return YES;
}

- (void) pasteboard:(NSPasteboard *)sender item:(NSPasteboardItem *)item provideDataForType:(NSString *)type
{
    RTLog(@"RTImageView - pasteboard");
    
    //sender has accepted the drag and now we need to send the data for the type we promised
    if ([type compare:NSFilenamesPboardType] == NSOrderedSame) {
        RTLog(@"RTImageView - Type Sound");
//        [sender setPropertyList:[NSArray arrayWithObject:[self.fileUrl path]] forType:NSFilenamesPboardType];
//        [sender setData:[NSData dataWithContentsOfURL:self.fileUrl] forType:NSPasteboardTypeSound];
    }
}

@end
