#define DEBUG_METHOD_TRACE 0

#include "MobileTerminal.h"

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <GraphicsServices/GraphicsServices.h>

#import "ColorMap.h"
#import "GestureView.h"
#import "Keyboard.h"
#import "MainViewController.h"
#import "Menu.h"
#import "PieView.h"
#import "Preferences.h"
#import "PTYTextView.h"
#import "Settings.h"
#import "SubProcess.h"
#import "VT100Screen.h"
#import "VT100Terminal.h"


@implementation Terminal

@synthesize identifier;
@synthesize process, screen, terminal;

- (id)initWithIdentifier:(int)identifier_ delegate:(id)delegate
{
    self = [super init];
    if (self) {
        identifier = identifier_;

        screen = [[VT100Screen alloc] initWithIdentifier:identifier];
        terminal = [[VT100Terminal alloc] init];
        [screen setTerminal:terminal];
        [terminal setScreen:screen];

        process = [[SubProcess alloc]
            initWithDelegate:delegate identifier:identifier];
    }
    return self;
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation MobileTerminal

@synthesize scrollers;
@synthesize activeTerminalIndex;

@synthesize landscape;
@synthesize controlKeyMode;
@synthesize menu;

@synthesize numTerminals;

+ (MobileTerminal *)application
{
    return [UIApplication sharedApplication];
}

+ (Menu *)menu
{
    return [[UIApplication sharedApplication] menu];
}

- (void)applicationDidFinishLaunching:(NSNotification *)unused
{
    settings = [[Settings sharedInstance] retain];
    [settings registerDefaults];
    [settings readUserDefaults];

    menu = [[Menu menuWithArray:[settings menu]] retain];

    mainController = [[MainViewController alloc] init];

    // --------------------------------------------------------- setup terminals

    terminals = [[NSMutableArray alloc] initWithCapacity:MAX_TERMINALS];

    for (numTerminals = 0; numTerminals < MAX_TERMINALS; numTerminals++)
        [self createTerminalWithIdentifier:numTerminals];

    // ------------------------------------------------------------- setup views
 
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [window addSubview:[mainController view]];
    [window makeKeyAndVisible];

    if (numTerminals > 1) {
        for (int i = numTerminals - 1; i >= 0; i--)
            [self setActiveTerminal:i];
    } else {
        [mainController updateFrames:YES];
    }
}

#pragma mark Confirmation dialog methods

- (void)confirmWithQuestion:(NSString *)question
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:question message:nil
        delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
    [alert show];
    [alert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index
{
    // NOTE: Currently only one alert view is used, so no need to ID the view
    if (index == 1)
        [self terminate];
}

#pragma mark Application events methods

- (BOOL)shouldTerminate
{
    BOOL ret = YES;
    for (Terminal *terminal in terminals) {
        if ([terminal.process isRunning]) {
            ret = NO;
            break;
        }
    }
    return ret;
}

- (void)applicationDidResume
{
    [self setStatusIconVisible:YES forTerminal:activeTerminalIndex];
}

- (void)applicationWillSuspend
{
    // FIXME: seems to not handle statusbar correctly
    if (self.activeView != [mainController view]) // preferences active
        [self togglePreferences];

    [self setStatusIconVisible:NO forTerminal:activeTerminalIndex];
}

// NOTE: must override this method to prevent application termination
- (void)applicationSuspend:(GSEventRef)event
{
    if ([self shouldTerminate])
        [self terminate];
}

- (void)applicationWillTerminate
{
    for (Terminal *terminal in terminals)
        [terminal.process close];

    [self setStatusIconVisible:NO forTerminal:activeTerminalIndex];
}

#pragma mark SubProcess delegate methods

- (void)process:(SubProcess *)process didExitWithCode:(NSInteger)code
{
    // Add delay so as not to jar user
    [NSThread sleepForTimeInterval:TERMINATION_DELAY];

    if ([self shouldTerminate])
        [self terminate];
    else
        [self nextTerminal];
}

#pragma mark IO handling methods

// Process output from the shell and pass it to the screen
- (void)handleStreamOutput:(const char *)c length:(unsigned int)len identifier:(int)tid
{
    if (tid < 0 || tid >= [terminals count])
        return;

    Terminal *terminal = [terminals objectAtIndex: tid];

    [terminal.terminal putStreamData:c length:len];

    // Now that we've got the raw data from the sub process, write it to the
    // terminal. We get back tokens to display on the screen and pass the
    // update in the main thread.
    VT100TCC token;
    while((token = [terminal.terminal getNextToken]),
            token.type != VT100_WAIT && token.type != VT100CC_NULL) {
        // process token
        if (token.type != VT100_SKIP) {
            if (token.type == VT100_NOTSUPPORT) {
                NSLog(@"%s(%d):not support token", __FILE__ , __LINE__);
            } else {
                [terminal.screen putToken:token];
            }
        } else {
            NSLog(@"%s(%d):skip token", __FILE__ , __LINE__);
        }
    }

    if (tid == activeTerminalIndex) {
        [[mainController activeTextView].tiledView performSelectorOnMainThread:@selector(updateAndScrollToEnd)
                                          withObject:nil
                                       waitUntilDone:NO];
    }
}

// Process input from the keyboard
- (void)handleKeyPress:(unichar)c
{
    if (!controlKeyMode) {
        if (c == 0x2022) {
            controlKeyMode = YES;
            return;
        } else if (c == 0x0a) // LF from keyboard RETURN
        {
            c = 0x0d; // convert to CR
        }
    } else {
        // was in ctrl key mode, got another key
        if (c < 0x60 && c > 0x40) {
            // Uppercase
            c -= 0x40;
        } else if (c < 0x7B && c > 0x60) {
            // Lowercase
            c -= 0x60;
        }
        [self setControlKeyMode:NO];
    }
    // Not sure if this actually matches anything. Maybe support high bits later?
    if ((c & 0xff00) != 0) {
        NSLog(@"Unsupported unichar: %x", c);
        return;
    }
    char simple_char = (char)c;

    [self.activeTerminal.process write:&simple_char length:1];
}

#pragma mark StatusBar methods

- (void)setStatusBarHidden:(BOOL)hidden duration:(double)duration
{
    [self setStatusBarMode:(hidden ? 104 : 0) duration:duration];
    [self setStatusBarHidden:hidden animated:NO];
}

- (void)setStatusIconVisible:(BOOL)visible forTerminal:(int)index
{
    if (visible) {
        NSString *name = [NSString stringWithFormat:@"MobileTerminal%d", index];
        if ([self respondsToSelector:@selector(addStatusBarImageNamed:removeOnExit:)])
            [self addStatusBarImageNamed:name removeOnExit:YES];
        else
            [self addStatusBarImageNamed:name removeOnAbnormalExit:YES];
    } else {
        [self removeStatusBarImageNamed:
            [NSString stringWithFormat:@"MobileTerminal%d", index]];
    }
}

- (void)statusBarMouseUp:(GSEventRef)event
{
    if (numTerminals > 1) {
        CGPoint pos = GSEventGetLocationInWindow(event).origin;
        float width = landscape ? window.frame.size.height : window.frame.size.width;
        if (pos.x > width/2 && pos.x < width *3/4) {
            [self prevTerminal];
        } else if (pos.x > width *3/4) {
            [self nextTerminal];
        } else {
            if (self.activeView == [mainController view])
                [self togglePreferences];
        }
    } else {
        if (self.activeView == [mainController view])
            [self togglePreferences];
    }
}

#pragma mark MenuView delegate methods

- (void)handleInputFromMenu:(NSString *)input
{
    if (input == nil) return;

    if ([input isEqualToString:@"[CTRL]"]) {
        if (![[MobileTerminal application] controlKeyMode])
            [[MobileTerminal application] setControlKeyMode:YES];
    } else if ([input isEqualToString:@"[KEYB]"]) {
        [mainController toggleKeyboard];
    } else if ([input isEqualToString:@"[NEXT]"]) {
        [self nextTerminal];
    } else if ([input isEqualToString:@"[PREV]"]) {
        [self prevTerminal];
    } else if ([input isEqualToString:@"[CONF]"]) {
        [self togglePreferences];
    } else if ([input isEqualToString:@"[QUIT]"]) {
        [self confirmWithQuestion:@"Quit Terminal?"];
    } else {
        [self.activeTerminal.process write:[input UTF8String] length:[input length]];
    }
}

- (void)setControlKeyMode:(BOOL)mode
{
    controlKeyMode = mode;
    [[mainController activeTextView].tiledView refreshCursorRow];
}

#pragma mark Terminal methods

- (void)setActiveTerminal:(int)terminal
{
    [self setActiveTerminal:terminal direction:0];
}

- (void)setActiveTerminal:(int)terminal direction:(int)direction
{
    activeTerminalIndex = terminal;
    [mainController switchToTerminal:terminal direction:direction];
}

- (void)prevTerminal
{
    if (numTerminals > 1) {
        int active = activeTerminalIndex - 1;
        if (active < 0)
            active = numTerminals-1;
        [self setActiveTerminal:active direction:-1];
    }
}

- (void)nextTerminal
{
    if (numTerminals > 1) {
        int active = activeTerminalIndex + 1;
        if (active >= numTerminals)
            active = 0;
        [self setActiveTerminal:active direction:1];
    }
}

- (void)createTerminalWithIdentifier:(int)identifier
{
    Terminal *terminal = [[Terminal alloc]
        initWithIdentifier:numTerminals delegate:self];
    [terminals addObject:terminal];

    [mainController addViewForTerminal:terminal];
    [terminal release];
}

- (void)destroyTerminalAtIndex:(int)index
{
    Terminal *terminal = [terminals objectAtIndex:index];
    [terminal.process closeSession];

    [mainController resetViewForTerminal:index];
    [terminals removeObject:terminal];
}

#pragma mark App/Preferences switching methods

#define fromRight 1
#define fromLeft 2

- (void)togglePreferences
{
    // Handle status bar and orientation
    if (self.activeView == [mainController view]) {
        preferencesController = [[PreferencesController alloc] init];
        if ([window interfaceOrientation] != 1) {
            // set orientation to portrait
            [self setStatusBarOrientation:1 animated:YES];
            [window _setRotatableViewOrientation:1 duration:0];
        }
    }

    // Change the view
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.75f];
    [UIView setAnimationTransition:
        (self.activeView == [mainController view] ? fromRight : fromLeft)
        forView:window cache:YES];
    [UIView setAnimationDelegate:self];

    if (self.activeView == [mainController view]) {
        [[mainController view] removeFromSuperview];
        [window addSubview:[preferencesController view]];
    } else {
        [[preferencesController view] removeFromSuperview];
        [window addSubview:[mainController view]];
    }

	[UIView commitAnimations];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    if (self.activeView == [mainController view]) {
        // The Preferences view has just been closed, release it
        [preferencesController release];
        preferencesController = nil;

        // reload settings
        [mainController updateColors];
    }
}

#pragma mark Properties

- (Terminal *)activeTerminal
{
    return [terminals objectAtIndex:activeTerminalIndex];
}

- (UIView *)activeView
{
    return [[window subviews] objectAtIndex:0];
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
