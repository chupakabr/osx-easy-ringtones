//
//  RMAppDelegate.h
//  RingtoneMaker
//
//  Created by Valeriy Chevtaev on 12/29/11.
//  Copyright (c) 2011 7bit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "RTDndView.h"
#import "RTSlider.h"

@interface RTAppDelegate : NSObject <NSApplicationDelegate, AVAudioPlayerDelegate>
{
@private
    AVAudioPlayer * audioPlayer_;
}

@property (assign) IBOutlet NSWindow * window;
@property (strong) IBOutlet RTDndView * dndView;

@property (strong) IBOutlet NSButton * playButton;
@property (strong) IBOutlet NSButton * ripButton;
@property (strong) IBOutlet NSButton * startButton;
@property (strong) IBOutlet NSButton * endButton;

@property (strong) IBOutlet NSTextField * startTimeText;
@property (strong) IBOutlet NSTextField * endTimeText;

@property (strong) IBOutlet NSProgressIndicator * progressIndicator;
@property (strong) IBOutlet RTSlider * audioSlider;

@property (strong) IBOutlet NSTextField * currentTimeLabel;

- (void) enableControls:(id)dummy;
- (void) disableControls:(id)dummy;

- (void) updateAudioSlider:(id)dummy;
- (IBAction) audioSliderUpdated:(id)sender;

- (IBAction) playButtonPressed:(id)sender;
- (IBAction) ripButtonPressed:(id)sender;
- (IBAction) startTimeButtonPressed:(id)sender;
- (IBAction) endTimeButtonPressed:(id)sender;

@end
