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
    
    [self cleanupCurrentAudio];
}

- (void) cleanupCurrentAudio
{
    RTLog(@"RTDndView - cleanupCurrentAudio()");
    
    if (!tempFilePath_) {
        return;
    }
    
    // Cleanup temp audio file
    RTLog(@"Cleaning up temporary audio file at path %@", tempFilePath_);
    NSError * errors;
    if (![[NSFileManager defaultManager] removeItemAtPath:tempFilePath_ error:&errors]) {
        RTLog(@"Cannot delete temporary audio file at path %@: %@", tempFilePath_, [errors description]);
    }
    
    [tempFilePath_ release];
}


#pragma mark - Business

- (NSString *) getTempFilePath:(NSString *)extension
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, extension]];
}

- (NSString *) prepareAudioFile:(NSString *)filePath
{
    NSString * extension = [[NSURL URLWithString:filePath] pathExtension];
    NSString * tempFilePath = [self getTempFilePath:extension];
    
    // Copy original audio file to newely created
    NSError * errors;
    if (![[NSFileManager defaultManager] copyItemAtPath:filePath toPath:tempFilePath error:&errors]) {
        [NSException raise:@"RTCannotCopyAudioFile" format:[errors description]];
    }
    
    return tempFilePath;
}


#pragma mark - Drag n Drop

// Before image is released

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    RTLog(@"draggingEntered()");
    
    NSPasteboard * pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        RTLog(@"Drag for SOUND FILE PATH");
        return NSDragOperationEvery;
    } else {
        RTLog(@"Drag for ITUNES ITEM");
        return NSDragOperationEvery;
    }
    
    RTLog(@"Drag for UNKNOWN");
    return NSDragOperationNone;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    RTLog(@"draggingEnded()");
    [[NSNotificationCenter defaultCenter] postNotificationName:RT_NOTIFICATION_END_DROPPING object:self userInfo:[NSDictionary dictionaryWithObject:tempFilePath_ forKey:@"audioFilePath"]];
    draggingInProgress_ = NO;
}

-(void)draggingExited:(id<NSDraggingInfo>)sender
{
    RTLog(@"draggingExited()");
    [[NSNotificationCenter defaultCenter] postNotificationName:RT_NOTIFICATION_END_DROPPING object:self];
    draggingInProgress_ = NO;
}


// After image is released

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    RTLog(@"prepareForDragOperation()");
    
    if (draggingInProgress_) {
        RTLog(@"Dragging is already in progress");
        return NO;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RT_NOTIFICATION_START_DROPPING object:self];
    
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    @synchronized(self)
    {
        
        RTLog(@"performDragOperation()");
        
        NSString * firstFilePath = nil;   //dropped file path
        
        @try
        {
            NSPasteboard * pboard;
            NSDragOperation sourceDragMask;
            
            sourceDragMask = [sender draggingSourceOperationMask];
            pboard = [sender draggingPasteboard];
            
            if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
                
                RTLog(@"Perform Drag for SOUND FILE PATH");
                
                // Sound file
                NSArray * files = [pboard propertyListForType:NSFilenamesPboardType];
                for (NSString * fpath in files) {
                    NSLog(@"Dragged file path found: %@", fpath);
                    firstFilePath = fpath;
                    break;
                }
                
            } else {
                
                RTLog(@"Perform Drag for ITUNES ITEM");
                
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
                                RTLog(@"iTunes file found: %@", urlString);
                                
                                firstFilePath = [[NSURL URLWithString:urlString] path];
                                if (firstFilePath != nil) {
                                    NSLog(@"iTunes file is valid and its path is %@", firstFilePath);
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
            RTLog(@"Cannot get and process dragged object's file path: %@", [e description]);
        }
        
        return YES;
        
    }   // synchronized
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
    RTLog(@"concludeDragOperation()");
}

@end
