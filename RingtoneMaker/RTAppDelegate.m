//
//  RMAppDelegate.m
//  RingtoneMaker
//
//  Created by Valeriy Chevtaev on 12/29/11.
//  Copyright (c) 2011 7bit. All rights reserved.
//

#import "RTAppDelegate.h"
#import "RTLog.h"
#import "RTNotifications.h"


#define RT_BUTTON_PLAY @"Play"
#define RT_BUTTON_STOP @"Stop"


@interface RTAppDelegate()

- (void) startDroppingNotificationHandler:(NSNotification *)notification;
- (void) endDroppingNotificationHandler:(NSNotification *)notification;
- (void) startRippingNotificationHandler:(NSNotification *)notification;
- (void) endRippingNotificationHandler:(NSNotification *)notification;

- (void) initAudioAndControls:(NSString *)filePath;

- (NSString *) getTimeString:(NSTimeInterval)time;
- (NSTimeInterval) getTimeInterval:(NSString *)timeStr;
- (void) removeFile:(NSURL *)fileURL;
- (void) removeFileAtPath:(NSString *)filePath;

@end


@implementation RTAppDelegate

@synthesize window = _window;
@synthesize dndView = _dndView;

@synthesize playButton = _playButton;
@synthesize play2Button = _play2Button;
@synthesize ripButton = _ripButton;
@synthesize startButton = _startButton;
@synthesize endButton = _endButton;

@synthesize startTimeText = _startTimeText;
@synthesize endTimeText = _endTimeText;

@synthesize audioSlider = _audioSlider;
@synthesize currentTimeLabel = _currentTimeLabel;
@synthesize progressIndicator = _progressIndicator;

@synthesize audioImageView = _audioImageView;
@synthesize dragMeLabel = _dragMeLabel;

- (void)dealloc
{
    RTLog(@"AppDelegate - dealloc()");
    
    // Audio Player cleanup
    if (audioPlayer_) {
        [audioPlayer_ release];
    }
    if (audioFileURL_) {
        [audioFileURL_ release];
    }
    if (outputURL_) {
        [outputURL_ release];
    }
    
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    RTLog(@"AppDelegate - applicationDidFinishLaunching()");
    
    // Setup notification handlers
    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(startDroppingNotificationHandler:) name:RT_NOTIFICATION_START_DROPPING object:nil];
    [notificationCenter addObserver:self selector:@selector(endDroppingNotificationHandler:) name:RT_NOTIFICATION_END_DROPPING object:nil];
    [notificationCenter addObserver:self selector:@selector(startRippingNotificationHandler:) name:RT_NOTIFICATION_START_RIPPING object:nil];
    [notificationCenter addObserver:self selector:@selector(endRippingNotificationHandler:) name:RT_NOTIFICATION_END_RIPPING object:nil];
    
    
    // Setup timer for handling audio player and slider changes
    [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateAudioSlider:) userInfo:nil repeats:YES];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    RTLog(@"AppDelegate - applicationWillTerminate() - start");
    
    // Delete temporary audio file
    if (audioFileURL_) {
        RTLog(@"Cleaning up temporary audio ORIG file at URL '%@'", audioFileURL_);
        [self removeFile:audioFileURL_];
    }
    
    // Delete temporary audio M4A file (ringtone file)
    if (outputURL_) {
        RTLog(@"Cleaning up temporary audio M4A file at URL '%@'", outputURL_);
        [self removeFile:outputURL_];
    }
    
    // RTDndView cleanup
    [self.dndView appWillClose];
    
    RTLog(@"AppDelegate - applicationWillTerminate() - exit");
}


#pragma mark - Methods

- (void) enableControls:(id)dummy
{
    RTLog(@"RTAppDelegate - enableControls()");
    
    [self.progressIndicator setHidden:YES];
    [self.progressIndicator stopAnimation:self];
    
    // enable buttons
    [self.playButton setEnabled:YES];
    [self.play2Button setEnabled:YES];
    [self.ripButton setEnabled:YES];
    [self.audioSlider setEnabled:YES];
    [self.startButton setEnabled:YES];
    [self.endButton setEnabled:YES];
}

- (void) disableControls:(NSNumber *)noProgressIndicator
{
    RTLog(@"RTAppDelegate - disableControls(%@)", noProgressIndicator);
    
    if (noProgressIndicator == nil || ![noProgressIndicator boolValue]) {
        [self.progressIndicator startAnimation:self];
        [self.progressIndicator setHidden:NO];
    } else {
        [self.progressIndicator setHidden:YES];
        [self.progressIndicator stopAnimation:self];        
    }
    
    // disable buttons
    [self.playButton setEnabled:NO];
    [self.play2Button setEnabled:NO];
    [self.ripButton setEnabled:NO];
    [self.audioSlider setEnabled:NO];
    [self.startButton setEnabled:NO];
    [self.endButton setEnabled:NO];
}

- (void) audioTrimmed:(id)dummy
{
    RTLog(@"RTAppDelegate - audioTrimmed()");
    
    // Show audio image view for dragging
    [self.audioImageView setFileUrl:outputURL_];
    [self.audioImageView setHidden:NO];
    [self.dragMeLabel setHidden:NO];
}

- (void) hideAudioTrimResult:(id)dummy
{
    RTLog(@"RTAppDelegate - hideAudioTrimResult()");
    
    // Show audio image view for dragging
    [self.audioImageView setFileUrl:nil];
    [self.audioImageView setHidden:YES];
    [self.dragMeLabel setHidden:YES];
    
    // Set start time to defaults
    [self.startTimeText setStringValue:[self getTimeString:0.0]];
    
    // Set end time to defaults
    [self.endTimeText setStringValue:[self getTimeString:30.0]];
    if (audioPlayer_) {
        if ([audioPlayer_ duration] < 30) {
            [self.endTimeText setStringValue:[self getTimeString:[audioPlayer_ duration]]];            
        }
    }
}


#pragma mark - Audio player actions

- (IBAction) playButtonPressed:(id)sender
{
    RTLog(@"RTAppDelegate - playButtonPressed()");
    
    @try
    {
        if ([self.playButton.title compare:RT_BUTTON_PLAY] == NSOrderedSame) {
            [audioPlayer_ setCurrentTime:[self.audioSlider doubleValue]];
            [audioPlayer_ play];
            [self.playButton setTitle:RT_BUTTON_STOP];
        } else {
            [audioPlayer_ stop];
            [self.playButton setTitle:RT_BUTTON_PLAY];
        }
    }
    @catch (NSException *e)
    {
        RTLog(@"Cannot play/stop audio player: %@", [e description]);
        [[NSAlert alertWithMessageText:@"Cannot play audio" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[e reason]] runModal];
    }
}

- (IBAction) playIntervalButtonPressed:(id)sender
{
    RTLog(@"RTAppDelegate - playIntervalButtonPressed()");
    
    [self.audioSlider setDoubleValue:[self getTimeInterval:[self.startTimeText stringValue]]];
    
    @try
    {
        [audioPlayer_ setCurrentTime:[self.audioSlider doubleValue]];
        if ([self.playButton.title compare:RT_BUTTON_PLAY] == NSOrderedSame) {
            [audioPlayer_ play];
            [self.playButton setTitle:RT_BUTTON_STOP];
        }
    }
    @catch (NSException *e)
    {
        RTLog(@"Cannot play/stop trimmed audio player: %@", [e description]);
        [[NSAlert alertWithMessageText:@"Cannot play trimmed audio" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[e reason]] runModal];
    }    
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    RTLog(@"RTAppDelegate - audioPlayerDidFinishPlaying()");
    [self.playButton performSelectorOnMainThread:@selector(setTitle:) withObject:RT_BUTTON_PLAY waitUntilDone:YES];
}

- (void) initAudioAndControls:(NSDictionary *)dict
{
    RTLog(@"RTAppDelegate - initAudioAndControls() with %@", dict);
    
    // Init new file path
    NSString * audioFilePath = [dict objectForKey:@"audioFilePath"];
    RTLog(@"RTAppDelegate - Audio file path is '%@'", audioFilePath);
    
    NSURL * newAudioUrl = [NSURL fileURLWithPath:audioFilePath];
    RTLog(@"RTAppDelegate - New Audio file URL is '%@', ext='%@'", newAudioUrl, [newAudioUrl pathExtension]);
    
    // Init new player
    NSError * errors;
    AVAudioPlayer * newAudioPlayer = [[[AVAudioPlayer alloc] initWithContentsOfURL:newAudioUrl error:&errors] autorelease];
    if (!newAudioPlayer) {
        RTLog(@"RTAppDelegate - Cannot init new AVAudioPlayer! file: '%@'", newAudioUrl);
        [NSException raise:@"RTCannotCreateAudioPlayer" format:[errors description]];
    }
    newAudioPlayer.delegate = self;
    
    // Cleanup previous player and replace with new
    if (audioPlayer_) {
        [audioPlayer_ stop];
        [audioPlayer_ release];
    }
    audioPlayer_ = [newAudioPlayer retain];
    
    // Init file paths
    if (audioFileURL_) {
        // Cleanup prev file
        RTLog(@"RTAppDelegate - Cleanup prev audioFileURL '%@'", audioFileURL_);
        [self removeFile:audioFileURL_];
        [audioFileURL_ release];
    }
    audioFileURL_ = [newAudioUrl retain];
    
    // Make output file URL
    NSString * outFilename = [dict objectForKey:@"origFileName"];
    if (!outFilename) {
        outFilename = @"Ringtone - Unknown Artist.mp3";
    }
    RTLog(@"RTAppDelegate - output file name is '%@'", outFilename);
    
    // TODO Check the file already exists
    NSURL * outputURLTemp = [[audioFileURL_ URLByDeletingLastPathComponent] URLByAppendingPathComponent:outFilename];
    if (outputURL_) {
        // Cleanup prev output file
        RTLog(@"RTAppDelegate - Cleanup prev outputURL '%@'", outputURL_);
        [self removeFile:outputURL_];
        [outputURL_ release];
    }
    outputURL_ = [[[outputURLTemp URLByDeletingPathExtension] URLByAppendingPathExtension:@"m4r"] retain];
    RTLog(@"RTAppDelegate - output file URL is '%@'", outputURL_);
    
    // Update slider values
    [self.audioSlider setDoubleValue:0.0];
    [self.audioSlider setMaxValue:[audioPlayer_ duration]];
    
    // Update play/stop button text
    [self.playButton setTitle:RT_BUTTON_PLAY];
    
    RTLog(@"RTAppDelegate - initAudioAndControls() DONE");
}

- (void) updateAudioSlider:(id)dummy
{
    if (!audioPlayer_ || ![audioPlayer_ isPlaying]) {
        return;
    }
    
    // Slider value
    [self.audioSlider setDoubleValue:[audioPlayer_ currentTime]];
    
    // Time string
    [self.currentTimeLabel setStringValue:[self getTimeString:[audioPlayer_ currentTime]]];
}

- (IBAction) audioSliderUpdated:(id)sender
{
    if (!audioPlayer_) {
        return;
    }
    
    // Audio player current time
    [audioPlayer_ setCurrentTime:[self.audioSlider doubleValue]];
    
    // Time string
    [self.currentTimeLabel setStringValue:[self getTimeString:[self.audioSlider doubleValue]]];
}

- (IBAction) ripButtonPressed:(id)sender
{
    RTLog(@"RTAppDelegate - ripButtonPressed()");
    
    @try {
            
        // Disable controls
        [self performSelectorOnMainThread:@selector(disableControls:) withObject:nil waitUntilDone:YES];
        
        // Setected trimming positions
        NSTimeInterval startPosition = [self getTimeInterval:[self.startTimeText stringValue]];
        NSTimeInterval endPosition = [self getTimeInterval:[self.endTimeText stringValue]];
        RTLog(@"Rip Audio File for interval: startTime(%f) endTime(%f)", startPosition, endPosition);
        
        // Check times if not out of bounds
        if (endPosition > [audioPlayer_ duration]) {
            RTLog(@"WARN Rip Audio: end time if greater that audio duration, %f > %f! Fixing to audio duration", endPosition, [audioPlayer_ duration]);
            endPosition = [audioPlayer_ duration];
        }
        if (startPosition > [audioPlayer_ duration]) {
            RTLog(@"WARN Rip Audio: start time if greater that audio duration, %f > %f! Fixing to zero", startPosition, [audioPlayer_ duration]);
            startPosition = 0.0;
        }
        NSTimeInterval duration = endPosition - startPosition;
        
        // Prepare for audio trimming
        RTLog(@"Output Rip file URL: '%@' -> '%@'", audioFileURL_, outputURL_);
        
        AVMutableComposition * avComposition = [AVMutableComposition composition];
        AVURLAsset * audioFileAsset = [AVURLAsset assetWithURL:audioFileURL_];
        
        int32_t timescale = [audioFileAsset duration].timescale;
        CMTimeRange audioDuration = CMTimeRangeMake(CMTimeMakeWithSeconds(startPosition, timescale), CMTimeMakeWithSeconds(duration, timescale));
        
        NSError * errors;
        if (![avComposition insertTimeRange:audioDuration ofAsset:audioFileAsset atTime:kCMTimeZero error:&errors]) {
            [NSException raise:@"RTCannotRipAudioFile" format:[errors description]];
        }
        
        // Check if the file already exists and remove it
        [self removeFile:outputURL_];
        
        // Export audio
        AVAssetExportSession * exporter = [[AVAssetExportSession alloc] initWithAsset:avComposition presetName:AVAssetExportPresetAppleM4A];
        exporter.outputURL = outputURL_;
        exporter.outputFileType = AVFileTypeAppleM4A;
        
        RTLog(@"Supported exporting types: %@", [exporter supportedFileTypes]);
        
        // ...with complete handler
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            RTLog(@"WOW! Audio file ripping completed successfully!");
            [exporter release];
            [self performSelectorOnMainThread:@selector(enableControls:) withObject:nil waitUntilDone:YES];
            [self performSelectorOnMainThread:@selector(audioTrimmed:) withObject:nil waitUntilDone:YES];
        }];
    }
    @catch (NSException *e)
    {
        RTLog(@"ERR! Cannot Rip audio composition: %@", [e description]);
        [[NSAlert alertWithMessageText:@"Cannot trim audio" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[e reason]] runModal];
        [self performSelectorOnMainThread:@selector(enableControls:) withObject:nil waitUntilDone:YES];
    }
}

- (IBAction) startTimeButtonPressed:(id)sender
{
    RTLog(@"RTAppDelegate - startTimeButtonPressed()");
    
    NSString * endTimeStr = [self.endTimeText stringValue];
    NSString * startTimeStr = [self getTimeString:[self.audioSlider doubleValue]];
    if ([startTimeStr compare:endTimeStr] == NSOrderedDescending) {
        [self.endTimeText performSelectorOnMainThread:@selector(setStringValue:) withObject:startTimeStr waitUntilDone:YES];
    }
    
    [self.startTimeText performSelectorOnMainThread:@selector(setStringValue:) withObject:[self getTimeString:[self.audioSlider doubleValue]] waitUntilDone:YES];
}

- (IBAction) endTimeButtonPressed:(id)sender
{
    RTLog(@"RTAppDelegate - endTimeButtonPressed()");
    
    NSString * startTimeStr = [self.startTimeText stringValue];
    NSString * endTimeStr = [self getTimeString:[self.audioSlider doubleValue]];
    if ([startTimeStr compare:endTimeStr] == NSOrderedDescending) {
        [self.startTimeText performSelectorOnMainThread:@selector(setStringValue:) withObject:endTimeStr waitUntilDone:YES];
    }
    
    [self.endTimeText performSelectorOnMainThread:@selector(setStringValue:) withObject:endTimeStr waitUntilDone:YES];
}


#pragma mark - Utils

- (NSString *) getTimeString:(NSTimeInterval)time
{
    int minutes = (int) floor(time/60);
    int seconds = (int) floor(time - 60*minutes);
    int millis = (int) ((time - minutes*60 - seconds)*100);
    
    return [NSString stringWithFormat:@"%.2d:%.2d.%.2d", minutes, seconds, millis];
}

- (NSTimeInterval) getTimeInterval:(NSString *)timeStr
{
    // ?##:##.##
    NSUInteger firstColonPos = [timeStr rangeOfString:@":"].location;
    NSUInteger secondColonPos = [timeStr rangeOfString:@":" options:NSBackwardsSearch].location;
    NSUInteger dotPos = [timeStr rangeOfString:@"."].location;
    
    NSTimeInterval tm = 0.0;
    
    if (firstColonPos != NSNotFound && secondColonPos != NSNotFound && dotPos != NSNotFound) {
        NSNumberFormatter * f = [[[NSNumberFormatter alloc] init] autorelease];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        
        // minutes to seconds
        int minutes = [[f numberFromString:[timeStr substringToIndex:firstColonPos]] intValue];
        
        // add seconds
        int seconds = [[f numberFromString:[timeStr substringWithRange:NSMakeRange(firstColonPos+1, 2)]] intValue];
        
        // add millis
        int millis = [[f numberFromString:[timeStr substringWithRange:NSMakeRange(dotPos+1, 2)]] intValue];
        
        // Eval time interval
        tm = minutes*60 + seconds + (double)millis/100;
    }
    
    return tm;
}

- (void) removeFile:(NSURL *)fileURL
{
    if (fileURL) {
        RTLog(@"Removing file at URL '%@'", fileURL);
        
        @try {
            NSError * errors;
            if (![[NSFileManager defaultManager] removeItemAtURL:fileURL error:&errors]) {
                RTLog(@"Cannot remove file at URL '%@': %@", fileURL, [errors description]);
            }
        }
        @catch (NSException *e)
        {
            RTLog(@"Cannot remove file at URL '%@': %@", fileURL, [e description]);
        }
    }    
}

- (void) removeFileAtPath:(NSString *)filePath
{
    if (filePath) {
        [self removeFile:[NSURL fileURLWithPath:filePath]];
    }
}

#pragma mark - Notifications handlers

- (void) startDroppingNotificationHandler:(NSNotification *)notification
{
    RTLog(@"RTAppDelegate - startDroppingNotificationHandler()");
    [self performSelectorOnMainThread:@selector(disableControls:) withObject:nil waitUntilDone:YES];
}

- (void) endDroppingNotificationHandler:(NSNotification *)notification
{
    RTLog(@"RTAppDelegate - endDroppingNotificationHandler()");
    
    NSString * audioFilePath = [[notification userInfo] objectForKey:@"audioFilePath"];
    @try {
        
        // Init audio player
        if (!audioFilePath) {
            [NSException raise:@"RTAudioFileNotFound" format:@"Empty audio file path passed in the notification object"];
        }
        
        RTLog(@"Audio File Path from notification is '%@'", audioFilePath);
        NSDictionary * dict = [[[notification userInfo] retain] autorelease];
        [self performSelectorOnMainThread:@selector(initAudioAndControls:) withObject:dict waitUntilDone:YES];
    }
    @catch (NSException *e)
    {
        RTLog(@"ERR! Cannot drop audio file: '%@'", [e description]);
        [self removeFileAtPath:audioFilePath];
        [[NSAlert alertWithMessageText:@"Invalid audio file" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[e reason]] runModal];
    }
    @finally
    {
        // Enable controls
        if (outputURL_ != nil) {
            [self performSelectorOnMainThread:@selector(enableControls:) withObject:nil waitUntilDone:YES];
        } else {
            [self performSelectorOnMainThread:@selector(disableControls:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:YES];
        }
        
        // Hide prev trim results
        [self performSelectorOnMainThread:@selector(hideAudioTrimResult:) withObject:nil waitUntilDone:YES];
    }
}

- (void) startRippingNotificationHandler:(NSNotification *)notification
{
    RTLog(@"RTAppDelegate - startRippingNotificationHandler()");
    [self performSelectorOnMainThread:@selector(disableControls:) withObject:nil waitUntilDone:YES];
}

- (void) endRippingNotificationHandler:(NSNotification *)notification
{
    RTLog(@"RTAppDelegate - endRippingNotificationHandler()");
    [self performSelectorOnMainThread:@selector(enableControls:) withObject:nil waitUntilDone:YES];
}


@end
