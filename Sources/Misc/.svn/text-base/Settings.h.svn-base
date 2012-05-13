//
// Settings.h
// Terminal

#import <Foundation/Foundation.h>

#import "Color.h"
#import "Constants.h"


@interface TerminalConfig : NSObject
{
    BOOL autosize;
    int width;

    NSString *font;
    int fontSize;
    float fontWidth;

    NSString *args;

    UIColor *colors_[NUM_TERMINAL_COLORS];
}

@property(nonatomic) BOOL autosize;
@property(nonatomic) int fontSize;
@property(nonatomic) float fontWidth;
@property(nonatomic, copy) NSString *font;
@property(nonatomic, readonly) UIColor **colors;
// NOTE: the following are used by SubProcess - should leave as atomic (?)
@property int width;
@property(copy) NSString *args;

+ (TerminalConfig *)configForActiveTerminal;
+ (TerminalConfig *)configForTerminal:(int)i;
- (NSString *)fontDescription;
- (UIColor **)colors;

@end

@interface Settings : NSObject
{
    NSString *arguments;
    NSArray *terminalConfigs;
    NSArray *menu;
    UIColor *gestureFrameColor;
    NSMutableDictionary *swipeGestures;
}

// NOTE: arguments is used by SubProcess - should leave as atomic (?)
@property(copy) NSString *arguments;
@property(nonatomic, readonly) NSArray* terminalConfigs;
@property(nonatomic, readonly) NSArray* menu;
@property(nonatomic, retain) UIColor *gestureFrameColor;
@property(nonatomic, readonly) NSDictionary *swipeGestures;

+ (Settings *)sharedInstance;

- (id)init;

- (void)registerDefaults;
- (void)readUserDefaults;
- (void)writeUserDefaults;

- (void)setCommand:(NSString *)command forGesture:(NSString *)zone;
- (UIColor **)gestureFrameColorRef;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
