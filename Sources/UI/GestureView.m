//
// GestureView.m
// Terminal

#import "GestureView.h"

#include <math.h>

#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/UIColor.h>
#import <UIKit/UIEvent.h>
#import <UIKit/UITouch.h>
#import <UIKit/UIView.h>

#import "Menu.h"
#import "MobileTerminal.h"
#import "PieView.h"
#import "Settings.h"
#import "Tools.h"


@protocol UITouchCompatibility

- (CGPoint)locationInView:(UIView *)view;
- (CGPoint)previousLocationInView:(UIView *)view;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation GestureView

- (id)initWithFrame:(CGRect)rect delegate:(id)inputDelegate
{
    self = [super initWithFrame:rect];
    if (self) {
        delegate = inputDelegate;
        menuView = [MenuView sharedInstance];
        pieView = [PieView sharedInstance];
        [self setBackgroundColor:[UIColor clearColor]];
        [self setOpaque:NO];
        [self setMultipleTouchEnabled:YES];
        //[super setTapDelegate:self];
    }
    return self;
}

- (BOOL)canBecomeFirstResponder
{
    return NO;
}

- (BOOL)canHandleGestures
{
    return YES;
}

- (BOOL)canHandleSwipes
{
    return YES;
}

- (void)drawRect:(CGRect)frame
{
    CGRect rect = [self bounds];
    rect.size.height -= 2;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorRef c = [[[Settings sharedInstance] gestureFrameColor] CGColor];
    const float pattern[2] = {1,4};
    CGContextSetLineDash(context, 0, pattern, 2);
    CGContextSetStrokeColorWithColor(context, c);
    CGContextStrokeRectWithWidth(context, rect, 1);
    CGContextFlush(context);
}

#pragma mark UIControl input tracking methods
// FIXME: is using a UIControl necessary now?

#pragma mark View toggle methods

- (void)toggleMenuView
{
    if ([menuView isVisible])
        [menuView hide];
    else
        [delegate showMenu:touchPos];
}

- (void)togglePieView
{
    if ([pieView isVisible])
        [pieView hide];
    else
        [delegate showPie:touchPos];
}

#pragma mark UIResponder touch input methods

static CGPoint getCenterPoint(NSSet *touches, UIView *view)
{
    // Calculate the average values of coordinates x and y
    float cx = 0, cy = 0;
    CGPoint p;
    for (UITouch *touch in touches) {
        p = [touch locationInView:view];
        cx += p.x;
        cy += p.y;
    }

    int count = [touches count];
    cx /= count;
    cy /= count;

    return CGPointMake(cx,cy);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // If first touch in a sequence, record the initial point
    if (fingersDown_ == 0)
        touchInitialPoint_ = getCenterPoint(touches, self);

    // Track number of fingers that have touched the screen in a given sequence
    fingersDown_ = MAX(fingersDown_, [[event allTouches] count]);

    // As we don't differntiate fingers, any touch will do
    UITouch *touch = [touches anyObject];
    int tc = [touch tapCount];
    if (tc == 2) {
        // Is a double-tap, cancel show/hide menu request
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    } else if (tc == 1) {
        // Schedule display of menu view
        touchPos  = [touch locationInView:self];
        if (![menuView isVisible])
            [self performSelector:@selector(toggleMenuView)
                withObject:nil afterDelay:0.1f];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![pieView isVisible])
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    //else
    //    [pieView handleTrackingAt:[menuView convertPoint:point fromView:self]];

    if ([menuView isVisible] && fingersDown_ == 1)
        [menuView handleTrackingAt:[[touches anyObject] locationInView:menuView]];

}

static int zoneForVector(CGPoint vector)
{
    float theta = atan2(-vector.y, vector.x);
    return ((7 - (lround(theta / M_PI_4 ) + 4) % 8) + 7) % 8;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    int fingersUp = [touches count];
    BOOL sequenceEnded = (fingersUp == [[event allTouches] count]);

    if (![pieView isVisible])
        // Cancel display of the pie view
        [NSObject cancelPreviousPerformRequestsWithTarget:self];

    if (sequenceEnded) {
        // NOTE: [touch isTap] alone is not used as the time delay that it allows
        //       for a touch to be recognized as a tap is unacceptably long
        UITouch *touch = [touches anyObject];
        if ([touch isTap] && ![pieView isVisible] && fingersDown_ == 1) {
            switch ([touch tapCount]) {
                case 1: // single tap
                    [menuView setDelegate:self];
                    [self performSelector:@selector(toggleMenuView)
                        withObject:nil
                        afterDelay:MENU_DELAY];
                    break;
                case 2: // double tap
                    [delegate toggleKeyboard];
                    break;
               default: // triple (or greater) tap
                    // Ignore (for now)
                    break;
            }
        } else { // a swipe
            NSString *command = nil;
            if ([menuView isVisible]) {
                command = [menuView handleTrackingEnd];
            } else {
                CGPoint touchFinalPoint = getCenterPoint(touches, self);
                CGPoint vector = CGPointMake(touchFinalPoint.x - touchInitialPoint_.x,
                        touchFinalPoint.y - touchInitialPoint_.y);
                float r = sqrtf(vector.x * vector.x + vector.y * vector.y);

                if ([pieView isVisible])
                    [pieView hide];

                // NOTE: Once multiple fingers touch the screen in a given sequence,
                //       the gesture becomes "two-finger", even if one of the fingers
                //       is removed before the other.
                //       This is done as it is difficult to remove both fingers from
                //       the screen at exactly the same time.
                NSDictionary *swipeGestures = [[Settings sharedInstance] swipeGestures];
                int zone = zoneForVector(vector);
                switch (fingersDown_) {
                    case 1:
                        // one-finger swipe
                        // NOTE: swipes less than 10 pixels get ignored
                        if ( r > 150.0f) { // long swipe
                            command = [swipeGestures objectForKey:ZONE_KEYS[zone + 8]];
                            if (![command length])
                                // Long not defined for this zone, fallback to short
                                command = [swipeGestures objectForKey:ZONE_KEYS[zone]];
                        } else if (r > 10.0f) { // short swipe
                            command = [swipeGestures objectForKey:ZONE_KEYS[zone]];
                        }
                        break;
                    case 2:
                   default:
                        // two-finger swipe
                        if (r > 10.0f)
                            command = [swipeGestures objectForKey:ZONE_KEYS[zone + 16]];
                        break;
                }
            }

            if (command)
                [[MobileTerminal application] handleInputFromMenu:command];

            // All fingers have left the screen, reset finger tracking
            fingersDown_ = 0;
        }
    } else {
        // FIXME: Adjust pie view, if visible/appropriate
        if ([pieView isVisible]) {
            return;
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
{
    // Reset all touch information
    fingersDown_ = 0;
}

#pragma mark MenuView delegate methods

- (void)menuFadedIn
{
    menuTapped = NO;
}

- (void)menuButtonPressed:(MenuButton *)button
{
    if (![button isMenuButton]) {
        BOOL keepMenu = NO;
        NSMutableString *command = [NSMutableString stringWithCapacity:16];
        [command setString:[button.item command]];

        if ([command hasSubstring:[[MobileTerminal menu] dotStringWithCommand:@"keepmenu"]]) {
            [command removeSubstring:[[MobileTerminal menu] dotStringWithCommand:@"keepmenu"]];
            [menuView deselectButton:button];
            keepMenu = YES;
        }

        if ([command hasSubstring:[[MobileTerminal menu] dotStringWithCommand:@"back"]]) {
            [command removeSubstring:[[MobileTerminal menu] dotStringWithCommand:@"back"]];
            [menuView popMenu];
            keepMenu = YES;
        }

        if (!keepMenu) {
            [menuView setDelegate:nil];
            [menuView hide];
        }

        [[MobileTerminal application] handleInputFromMenu:command];
    }
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
