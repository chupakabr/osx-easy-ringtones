//
//  RTDndView.m
//  RingtoneMaker
//
//  Created by Valeriy Chevtaev on 12/29/11.
//  Copyright (c) 2011 7bit. All rights reserved.
//

#import "RTDndView.h"
#import "RTLog.h"
#import "RTNotifications.h"
#import "RTImageView.h"


#define RTItunesPboardType @"com.apple.pasteboard.promised-file-url"


@interface RTDndView()
- (NSString *) getTempFilePath:(NSString *)extension;
- (NSString *) prepareAudioFile:(NSString *)filePath;
@end


@implementation RTDndView

- (id)initWithFrame:(NSRect)frame
{
    RTLog(@"RTDndView - initWithFrame()");
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
        // DnD
        [self registerForDraggedTypes:[NSArray arrayWithObjects:RTItunesPboardType, NSFilenamesPboardType, nil]];
        //NSPasteboardTypeSound, NSFilesPromisePboardType
    }
    
    return self;
}

- (void) dealloc
{
    RTLog(@"RTDndView - dealloc()");
    
    if (tempFilePath_) {
        [tempFilePath_ release];
    }
    
    if (origFileName_) {
        [origFileName_ release];
    }
    
    [self release];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
//    [[NSColor blueColor] set];
//    NSRectFill(dirtyRect);
}

- (void) appWillClose
{
    RTLog(@"RTDndView - appWillClose()");
    
    if (origFileName_) {
        [origFileName_ release];
    }
    
    if (tempFilePath_) {
        [tempFilePath_ release];
    }
}

- (void) cleanupCurrentAudio
{
    RTLog(@"RTDndView - cleanupCurrentAudio()");
    
    if (origFileName_) {
        [origFileName_ release];
    }
    
    if (tempFilePath_) {
        [tempFilePath_ release];
    }
}


#pragma mark - Business

- (NSString *) getTempFilePath:(NSString *)extension
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"rtone_%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, extension]];
}

- (NSString *) prepareAudioFile:(NSString *)filePath
{
    RTLog(@"RTDndView - prepareAudioFile");
    
    NSString * extension = [[NSURL fileURLWithPath:filePath] pathExtension];
    RTLog(@"EXTENSION '%@'", extension);
    if ([extension characterAtIndex:([extension length]-1)] == 0) {
        extension = [extension substringToIndex:3];
        RTLog(@"EXTENSION last char is zero so it was trimmed to '%@'", extension);
    }
    
    NSString * tempFilePath = [self getTempFilePath:extension];
    RTLog(@"RTDndView - tempFilePath is '%@'", tempFilePath);
    
    // Copy original audio file to newely created
    NSError * errors;
    if (![[NSFileManager defaultManager] copyItemAtPath:filePath toPath:tempFilePath error:&errors]) {
        [NSException raise:@"RTCannotCopyAudioFile" format:[errors description]];
    }
    
    // Store orig file name
    origFileName_ = [[[filePath pathComponents] lastObject] retain];
    
    return tempFilePath;
}


#pragma mark - Drag n Drop

// Before image is released

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    RTLog(@"RTDndView - draggingEntered()");
    
    NSPasteboard * pboard;
    NSDragOperation sourceDragMask;
    id draggingSource = [sender draggingSource];
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    
    // Check if it's local
    if (draggingSource && [draggingSource isKindOfClass:[RTImageView class]]) {
        RTLog(@"RTDndView - is local dragging");
        return NSDragOperationNone;
    }
    
    // OK pboard
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        RTLog(@"RTDndView - Drag for SOUND FILE PATH");
        return NSDragOperationEvery;
    } else {
        RTLog(@"RTDndView - Drag for ITUNES ITEM");
        return NSDragOperationEvery;
    }
    
    RTLog(@"RTDndView - Drag for UNKNOWN");
    return NSDragOperationNone;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    RTLog(@"RTDndView - draggingEnded()");
    
    // Check if it's local
    id draggingSource = [sender draggingSource];
    NSPasteboard * pboard = [sender draggingPasteboard];
    
    if ((!draggingSource || ![draggingSource isKindOfClass:[RTImageView class]]) && [[pboard name] compare:RTPasteBoardName] != NSOrderedSame) {
        RTLog(@"RTDndView - draggingEnded() IS NOT LOCAL dragging, Dragging Source is %@", draggingSource);
        
        NSDictionary * notificationData = [NSDictionary dictionaryWithObjectsAndKeys:tempFilePath_, @"audioFilePath", origFileName_, @"origFileName", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:RT_NOTIFICATION_END_DROPPING object:self userInfo:notificationData];
    } else {
        RTLog(@"RTDndView - draggingEnded() IS LOCAL dragging");
    }
    
    draggingInProgress_ = NO;
}

-(void)draggingExited:(id<NSDraggingInfo>)sender
{
    RTLog(@"RTDndView - draggingExited()");
    draggingInProgress_ = NO;
}


// After image is released

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    RTLog(@"RTDndView - prepareForDragOperation()");
    
    if (draggingInProgress_) {
        RTLog(@"RTDndView - Dragging is already in progress");
        return NO;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RT_NOTIFICATION_START_DROPPING object:self];
    
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    @synchronized(self)
    {
        
        RTLog(@"RTDndView - performDragOperation()");
        
        NSString * firstFilePath = nil;   //dropped file path
        
        @try
        {
            NSPasteboard * pboard;
            NSDragOperation sourceDragMask;
            
            sourceDragMask = [sender draggingSourceOperationMask];
            pboard = [sender draggingPasteboard];
            
            if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
                
                RTLog(@"RTDndView - Perform Drag for SOUND FILE PATH");
                
                // Sound file
                NSArray * files = [pboard propertyListForType:NSFilenamesPboardType];
                for (NSString * fpath in files) {
                    RTLog(@"RTDndView - Dragged file path found: %@", fpath);
                    firstFilePath = fpath;
                    break;
                }
                
            } else {
                
                RTLog(@"RTDndView - Perform Drag for ITUNES ITEM");
                
                // iTunes sound
                NSArray * files = [pboard pasteboardItems];
                for (NSPasteboardItem * item in files) {
                    
                    if (firstFilePath != nil) {
                        break;
                    }
                    
                    for (NSString * type in [pboard types]) {
                        
                        if ([[item types] containsObject:type]) {
                            
                            NSString * urlString = [item stringForType:type];
                            if (urlString) {
                                RTLog(@"RTDndView - iTunes file found: %@", urlString);
                                
                                firstFilePath = [[NSURL URLWithString:urlString] path];
                                if (firstFilePath != nil) {
                                    RTLog(@"RTDndView - iTunes file is valid and its path is %@", firstFilePath);
                                }
                                
                                break;
                            }
                        }
                    }
                }
                
            }
            
            if (!firstFilePath) {
                [NSException raise:@"RTDraggedFileNotFound" format:@"No file found from dragged object(s)"];
            }
            
            //
            // Start processing the file
            
            RTLog(@"Processing of dragged file is starting... (%@)", firstFilePath);
            [self cleanupCurrentAudio];
            tempFilePath_ = [[self prepareAudioFile:firstFilePath] retain];
            
            RTLog(@"Processing of dragged file completed successfully... (tempfile: %@)", tempFilePath_);
        }
        @catch (NSException *e)
        {
            RTLog(@"RTDndView - Cannot get and process dragged object's file path: %@", [e description]);
            return NO;
        }
        
        return YES;
        
    }   // synchronized
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
    RTLog(@"RTDndView - concludeDragOperation()");
}

@end
