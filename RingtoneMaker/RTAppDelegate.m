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
    [self.dndView appWillClose];
    
    // Delete temporary audio M4A file (ringtone file)
    if (outputURL_) {
        RTLog(@"Cleaning up temporary audio M4A file at URL %@", outputURL_);
        NSError * errors;
        if (![[NSFileManager defaultManager] removeItemAtURL:outputURL_ error:&errors]) {
            RTLog(@"Cannot delete temporary audio M4A file at URL %@: %@", outputURL_, [errors description]);
        }
    }
    
    RTLog(@"AppDelegate - applicationWillTerminate() - exit");
}


#pragma mark - Methods

- (void) enableControls:(id)dummy
{
    RTLog(@"RTAppDelegate - enableControls()");
    [self.progressIndicator setHidden:YES];
    [self.progressIndicator startAnimation:self];
    
    // enable buttons
    [self.playButton setEnabled:YES];
    [self.play2Button setEnabled:YES];
    [self.ripButton setEnabled:YES];
    [self.audioSlider setEnabled:YES];
    [self.startButton setEnabled:YES];
    [self.endButton setEnabled:YES];
}

- (void) disableControls:(id)dummy
{
    RTLog(@"RTAppDelegate - disableControls()");
    [self.progressIndicator stopAnimation:self];
    [self.progressIndicator setHidden:NO];
    
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
    }
}

- (IBAction) playIntervalButtonPressed:(id)sender
{
    RTLog(@"RTAppDelegate - playIntervalButtonPressed()");
    
    [self.audioSlider setDoubleValue:[self getTimeInterval:[self.startTimeText stringValue]]];
    [self playButtonPressed:sender];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    RTLog(@"RTAppDelegate - audioPlayerDidFinishPlaying()");
    [self.playButton performSelectorOnMainThread:@selector(setTitle:) withObject:RT_BUTTON_PLAY waitUntilDone:YES];
}

- (void) initAudioAndControls:(NSString *)filePath
{
    RTLog(@"RTAppDelegate - initAudioAndControls() with %@", filePath);
    
    // Cleanup previous player
    if (audioPlayer_) {
        [audioPlayer_ stop];
        [audioPlayer_ release];
    }
    
    // Init file paths
    if (audioFileURL_) {
        [audioFileURL_ release];
    }
    audioFileURL_ = [[NSURL alloc] initFileURLWithPath:filePath];
    
    if (outputURL_) {
        [outputURL_ release];
    }
    outputURL_ = [[[audioFileURL_ URLByDeletingPathExtension] URLByAppendingPathExtension:@"m4r"] retain];
    
    // Init new player
    NSError * errors;
    audioPlayer_ = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL_ error:&errors];
    if (!audioPlayer_) {
        [NSException raise:@"RTCannotCreateAudioPlayer" format:[errors description]];
    }
    audioPlayer_.delegate = self;
    
    // Update slider values
    [self.audioSlider setDoubleValue:0.0];
    [self.audioSlider setMaxValue:[audioPlayer_ duration]];
    
    // Update play/stop button text
    [self.playButton setTitle:RT_BUTTON_PLAY];
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
    
    // Disable controls
    [self performSelectorOnMainThread:@selector(disableControls:) withObject:nil waitUntilDone:YES];
    
    // Setected trimming positions
    NSTimeInterval startPosition = [self getTimeInterval:[self.startTimeText stringValue]];
    NSTimeInterval endPosition = [self getTimeInterval:[self.endTimeText stringValue]];
    RTLog(@"Rip Audio File for interval: startTime(%f) endTime(%f)", startPosition, endPosition);
    
    // Prepare for audio trimming
    RTLog(@"Output Rip file URL: %@ -> %@", audioFileURL_, outputURL_);
    
    AVMutableComposition * avComposition = [AVMutableComposition composition];
    AVURLAsset * audioFileAsset = [AVURLAsset assetWithURL:audioFileURL_];
    
    int32_t timescale = [audioFileAsset duration].timescale;
    CMTimeRange audioDuration = CMTimeRangeMake(CMTimeMakeWithSeconds(startPosition, timescale), CMTimeMakeWithSeconds(endPosition-startPosition, timescale));
    
    NSError * errors;
    if (![avComposition insertTimeRange:audioDuration ofAsset:audioFileAsset atTime:kCMTimeZero error:&errors]) {
        [NSException raise:@"RTCannotRipAudioFile" format:[errors description]];
    }
    
    // Export audio
    AVAssetExportSession * exporter = [[AVAssetExportSession alloc] initWithAsset:avComposition presetName:AVAssetExportPresetAppleM4A];
    exporter.outputURL = outputURL_;
    exporter.outputFileType = AVFileTypeAppleM4A;
	
    RTLog(@"Supported exporting types: %@", [exporter supportedFileTypes]);
    
    // ...with complete handler
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        RTLog(@"WOW! Audio file ripping completed successfully!");
        [self performSelectorOnMainThread:@selector(enableControls:) withObject:nil waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(audioTrimmed:) withObject:nil waitUntilDone:YES];
        [exporter release];
	}];    
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


#pragma mark - Notifications handlers

- (void) startDroppingNotificationHandler:(NSNotification *)notification
{
    RTLog(@"RTAppDelegate - startDroppingNotificationHandler()");
    
    [self performSelectorOnMainThread:@selector(disableControls:) withObject:nil waitUntilDone:YES];
}

- (void) endDroppingNotificationHandler:(NSNotification *)notification
{
    RTLog(@"RTAppDelegate - endDroppingNotificationHandler()");
    
    // Init audio player
    NSString * audioFilePath = [[notification userInfo] valueForKey:@"audioFilePath"];
    if (!audioFilePath) {
        [NSException raise:@"RTAudioFileNotFound" format:@"Empty audio file path passed in the notification object"];
    }
    
    RTLog(@"Audio File Path from notification is %@", audioFilePath);
    [self performSelectorOnMainThread:@selector(initAudioAndControls:) withObject:audioFilePath waitUntilDone:YES];
    
    // Enable controls
    [self performSelectorOnMainThread:@selector(enableControls:) withObject:nil waitUntilDone:YES];
}

- (void) startRippingNotificationHandler:(NSNotification *)notification
{
    RTLog(@"RTAppDelegate - startRippingNotificationHandler()");
    
    // TODO
    [self performSelectorOnMainThread:@selector(disableControls:) withObject:nil waitUntilDone:YES];
}

- (void) endRippingNotificationHandler:(NSNotification *)notification
{
    RTLog(@"RTAppDelegate - endRippingNotificationHandler()");
    
    // TODO
    [self performSelectorOnMainThread:@selector(enableControls:) withObject:nil waitUntilDone:YES];
}


@end
