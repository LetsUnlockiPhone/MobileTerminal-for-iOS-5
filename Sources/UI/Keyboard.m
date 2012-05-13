// Keyboard.m

#import "Keyboard.h"

#import <UIKit/UIDefaultKeyboardInput.h>
#import <UIKit/UIKeyboardCandidateList-Protocol.h>
#import <UIKit/UIKeyboardImpl.h>
#import <UIKit/UIScreen.h>
#import <UIKit/UIView-Animation.h>
#import <UIKit/UIView-Geometry.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIView-Rendering.h>

#import "Constants.h"
#import "MobileTerminal.h"


@interface TextInputHandler : UIDefaultKeyboardInput
{
    ShellKeyboard *shellKeyboard;
}

- (id)initWithKeyboard:(ShellKeyboard *)keyboard;

@end

//_______________________________________________________________________________

@implementation TextInputHandler

- (id)initWithKeyboard:(ShellKeyboard *)keyboard;
{
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)];
    if ( self ) {
        shellKeyboard = keyboard;
        [[self textInputTraits] setAutocorrectionType:1];
        [[self textInputTraits] setAutocapitalizationType:0];
        [[self textInputTraits] setEnablesReturnKeyAutomatically:NO];
    }
    return self;
}

// FIXME: is this method no longer needed?
#if 0
- (BOOL)webView:(id)fp8 shouldDeleteDOMRange:(id)fp12
{
    [shellKeyboard handleKeyPress:0x08];
    return false;
}

#endif

- (void)deleteBackward
{
    [shellKeyboard handleKeyPress:0x08];
}

- (void)insertText:(id)character
{
    if ([character length] != 1)
        [NSException raise:@"Unsupported" format:@"Unhandled multi-char insert!"];
    [shellKeyboard handleKeyPress:[character characterAtIndex:0]];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation ShellKeyboard

@synthesize inputDelegate;
@synthesize animationDelegate;
@synthesize visible;

- (id)initWithDefaultRect
{
    self = [super initWithDefaultSize];
    if (self) {
        [self setOrigin:CGPointMake(0, 264.0f)];
        handler = [[TextInputHandler alloc] initWithKeyboard:self];
        visible = YES;
    }
    return self;
}

- (void)dealloc
{
    [handler release];
    [super dealloc];
}

- (void)handleKeyPress:(unichar)c
{
    [inputDelegate handleKeyPress:c];
}

- (void)setEnabled:(BOOL)enabled
{
    if (enabled) {
        [self activate];
        [[UIKeyboardImpl activeInstance] setDelegate:handler];
    } else {
        [[UIKeyboardImpl activeInstance] setDelegate:nil];
        [self deactivate];
    }
}

- (CGRect)keyboardFrame
{
    int orientation = [[[self superview] window] interfaceOrientation];
    CGSize keybSize = [UIKeyboard defaultSizeForInterfaceOrientation:orientation];
    CGSize superSize = [[self superview] bounds].size;
    return CGRectMake(0, superSize.height - keybSize.height,
            superSize.width, keybSize.height);
}

- (void)updateGeometry
{
    if ([self superview]) {
        CGRect frame = [self keyboardFrame];
        if (!visible)
            frame.origin.y += frame.size.height;
        [self setFrame:frame];
    }
}

- (void)setVisible:(BOOL)visible_ animated:(BOOL)animated
{
    if (visible != visible_) {
        if (!visible)
            // Make sure the size and position matches the orientation
            [self updateGeometry];

        CGRect frame = [self frame];
        if (visible) {
            // Hide the keyboard
            frame.origin.y += frame.size.height;
            [UIView beginAnimations:@"keyboardFadeOut"];
            [UIView setAnimationDuration:
                (animated ? KEYBOARD_ANIMATE_OUT_TIME : 0)];
            [UIView setAnimationDelegate:animationDelegate];
            [UIView setAnimationDidStopSelector:
                @selector(keyboardDidDisappear:finished:context:)];
            [self setFrame:frame];
            [UIView commitAnimations];
        } else {
            // Show the keyboard
            frame.origin.y -= frame.size.height;
            [UIView beginAnimations:@"keyboardFadeIn"];
            [UIView setAnimationDuration:
                (animated ? KEYBOARD_ANIMATE_IN_TIME : 0)];
            [UIView setAnimationDelegate:animationDelegate];
            [UIView setAnimationDidStopSelector:
                 @selector(keyboardDidAppear:finished:context:)];
            [self setFrame:frame];
            [UIView commitAnimations];
        }

        visible = !visible;
    }
}

// NOTE: Override to prevent transform from being changed;
//       Instead, orientation is controlled by superview
- (void)setTransform:(CGAffineTransform)transform
{
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
