// ColorMap.h
//
// ColorMap is not at all thread safe.

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#import "Constants.h"

@class UIColor;

enum {
    BG_COLOR = 16,
    FG_COLOR,
    FG_COLOR_BOLD,
    FG_COLOR_CURSOR,
    BG_COLOR_CURSOR,
    NUM_COLORS = BG_COLOR + MAX_TERMINALS * NUM_TERMINAL_COLORS,
};

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface ColorMap : NSObject
{
    UIColor *table[NUM_COLORS];
}

+ (ColorMap *)sharedInstance;
- (UIColor *)colorForCode:(unsigned int)index termid:(int)termid;
- (void)setTerminalColor:(UIColor *)color atIndex:(int)index termid:(int)termid;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
