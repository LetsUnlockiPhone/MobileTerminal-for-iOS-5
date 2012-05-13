#import "PieView.h"

#import <CoreGraphics/CGColor.h>
#import <UIKit/UIControl-UIControlPrivate.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UIImage-UIImageDeprecated.h>
#import <UIKit/UIView-Animation.h>
#import <UIKit/UIView-Geometry.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIView-Rendering.h>

#import "Color.h"
#import "Constants.h"
#import "Log.h"
#import "Menu.h"
#import "Settings.h"


bool CGFontGetGlyphsForUnichars(CGFontRef, unichar[], CGGlyph[], size_t);
extern CGFontRef CGContextGetFont(CGContextRef);
extern CGContextRef UIGraphicsGetCurrentContext();

@implementation PieButton

@synthesize command;

- (id)initWithFrame:(CGRect)frame identifier:(int)identifier_
{
    self = [super initWithTitle:@""];
    if (self) {
        identifier = identifier_;

        NSBundle *bundle = [NSBundle mainBundle];

        // Load pie button normal image
        NSString *imagePath = [bundle pathForResource:[NSString stringWithFormat:
            (identifier % 2 ? @"pie_gray%d" : @"pie_white%d"),
            (identifier + 1)] ofType: @"png"];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
        [self setImage:image forState:0];

        // Load pie button selected image
        imagePath = [bundle pathForResource: [NSString stringWithFormat:
            @"pie_blue%d", (identifier + 1)] ofType: @"png"];
        image = [[UIImage alloc] initWithContentsOfFile:imagePath];
        [self setImage:image forState:1];
        [self setImage:image forState:4];

        [self setDrawContentsCentered:YES];
        [self setAutosizesToFit:NO];
        [self setEnabled:YES];
        [self setOpaque:NO];

        if (identifier % 2) {
            // gray
            [self setTitleColor:[UIColor whiteColor] forState:0]; // normal
            [self setShadowColor:colorWithRGBA(.25,.25,.25,1) forState:0]; // normal
            _shadowOffset = CGSizeMake(0.0, 1.0);
        } else {
            // white
            [self setTitleColor:[UIColor blackColor] forState:0]; // normal
            [self setShadowColor:[UIColor whiteColor] forState:0]; // normal
            _shadowOffset = CGSizeMake(0.0, -1.0);
        }
        [self setTitleColor:[UIColor whiteColor] forState:1]; // pressed
        [self setTitleColor:[UIColor whiteColor] forState:4]; // selected
        [self setShadowColor:colorWithRGBA(0.1,0.1,0.7,1) forState:1]; // pressed
        [self setShadowColor:colorWithRGBA(0.1,0.1,0.7,1) forState:4]; // selected

        [self setOrigin:frame.origin];

        unichar dotChar[1] = {0x2022};
        dot = [[NSString alloc] initWithCharacters:dotChar length:1];
    }
    return self;
}

- (void)dealloc
{
    [dot release];
    [super dealloc];
}

#pragma mark Other

- (void)drawTitleAtPoint:(CGPoint)point width:(float)width
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    float height = 14.0f;

    NSString *fontName = @"HelveticaBold";
    CGContextSelectFont(context, [fontName UTF8String], height, kCGEncodingMacRoman);
    CGFontRef font = CGContextGetFont(context);

    NSString *text = [self title];
    size_t len = [text length];

    CGContextSetTextDrawingMode(context, kCGTextInvisible);
    unichar chars[12] = {0};
    CGGlyph glyphs[12] = {0};

    int numChars = 12;
    float textWidth = 100;
    while (textWidth > 50 && numChars > 4) {
        len = len > numChars-1 ? numChars-1 : len;
        [text getCharacters:chars range: NSMakeRange(0, len)];

        CGFontGetGlyphsForUnichars(font, chars, glyphs, len);

        CGContextSetTextPosition(context, 0, 0);
        CGContextShowGlyphs(context, glyphs, len);
        CGPoint end = CGContextGetTextPosition(context);

        textWidth = end.x;
        numChars--;
    }

    CGAffineTransform scale = CGAffineTransformMake(1, 0, 0, -1, 0, 1.0);
    float rot[8] = {M_PI/2, M_PI/4, 0, -M_PI/4, M_PI/2, M_PI/4, 0, -M_PI/4};

    CGAffineTransform transform = scale;

    if ((identifier % 4) != 0 || textWidth > 26)
        transform = CGAffineTransformRotate(scale, rot[identifier]);

    CGContextSetTextMatrix(context, transform);

    CGContextSetFont(context, font);
    CGContextSetFontSize(context, height);

    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetFillColorWithColor(context, [[self titleColorForState:[self state]] CGColor]);
    CGContextSetShadowWithColor(context,
        (!([self state] & 4)) ? _shadowOffset : CGSizeMake(0.0f, 1.0f),
        0.0f, [[self shadowColorForState:[self state]] CGColor]);

    CGPoint center = CGPointMake(-0.5f *textWidth, -0.25 *height);
    CGPoint p = CGPointApplyAffineTransform(center, transform);
    CGContextShowGlyphsAtPoint(context,
        0.5 * [self bounds].size.width + p.x,
        0.5 * [self bounds].size.height + p.y, glyphs, len);

    CGContextRestoreGState(context);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
}

- (NSString *)dotStringWithCommand:(NSString *)cmd
{
    return [NSString stringWithFormat:@"%@%@", dot, cmd];
}

#pragma mark Properties

- (void)setCommand:(NSString *)command_
{
    if (command != command_) {
        [command release];
        command = [command_ copy];
        [self setTitle:[self commandString]];
    }
}

static NSMutableString *convertCommandString(PieButton *button, NSString *cmd, BOOL isCommand)
{
    NSMutableString *s = [NSMutableString stringWithCapacity:64];
    [s setString:cmd];

    int i = 0;
    while (STRG_CTRL_MAP[i].str) {
        int toLength = 0;
        while (STRG_CTRL_MAP[i].chars[toLength]) toLength++;
        NSString *from = [button dotStringWithCommand:STRG_CTRL_MAP[i].str];
        NSString *to = [NSString stringWithCharacters:STRG_CTRL_MAP[i].chars length:toLength];

        if (isCommand)
            // convert to command string
            [s replaceOccurrencesOfString:to withString:from
                options:0 range:NSMakeRange(0, [s length])];
        else
            // convert to command
            [s replaceOccurrencesOfString:from withString:to
                options:0 range:NSMakeRange(0, [s length])];

        i++;
    }
    return s;
}

- (NSString *)commandString
{
    return convertCommandString(self, [self command], YES);
}

- (void)setCommandString:(NSString *)cmdString
{
    [self setCommand:convertCommandString(self, cmdString, NO)];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation PieView

@synthesize buttons;
@synthesize visible;
@synthesize delegate;

+ (PieView *)sharedInstance
{
    static PieView *instance = nil;
    if (instance == nil) {
        instance = [[PieView alloc] init];
    }
    return instance;
}

- (id)init
{
    self = [super initWithFrame:CGRectMake(0, 0, 210, 215)];
    if (self) {
        visible = YES;
        [self setOpaque:NO];

        NSBundle *bundle = [NSBundle mainBundle];
        NSString *imagePath = [bundle pathForResource: @"pie_back" ofType: @"png"];
        pie_back = [[UIImage alloc] initWithContentsOfFile:imagePath];

        buttons = [[NSMutableArray alloc] initWithCapacity:8];
        for (int i = 0; i < 8; i++) {
            const float x[] = { 5.0, 12.0, 69.0, 126.0, 161.0, 126.0, 69.0, 12.0};
            const float y[] = { 73.0, 15.0, 7.0, 15.0, 73.0, 129.0, 165.0, 129.0};

            PieButton *button = [[PieButton alloc]
                initWithFrame:CGRectMake(x[i], y[i], 0, 0) identifier:i];
            [buttons addObject:button];
            [button addTarget:self action:@selector(buttonPressed:) forEvents:64];
            [self addSubview:button];
            [button release];
        }
    }
    return self;
}

- (void)dealloc
{
    [buttons release];
    [pie_back release];

    [super dealloc];
}

- (void)drawRect:(CGRect)frame
{
    [pie_back compositeToPoint:CGPointMake(0.0f, 0.0f) operation:2];
}

#pragma mark UIView methods

- (BOOL)ignoresMouseEvents
{
    return NO;
}

#pragma mark Button-related methods

- (PieButton *)buttonAtIndex:(int)index
{
    return [[self buttons] objectAtIndex:index];
}

- (void)selectButton:(PieButton *)button
{
    [activeButton setSelected:NO];
    [button setSelected:YES];
    activeButton = button;
}

- (void)deselectButton:(PieButton *)button
{
    [button setSelected:NO];
    if (button == activeButton)
        activeButton = nil;
}

- (void)buttonPressed:(PieButton *)button
{
    if (button != activeButton) {
        [self selectButton:button];
        if ([delegate respondsToSelector:@selector(pieButtonPressed:)])
            [delegate performSelector:@selector(pieButtonPressed:) withObject:activeButton];
    }
}

#pragma mark Display-related methods

- (void)showAtPoint:(CGPoint)point
{
    if (!visible) {
        CGSize selfSize = [self bounds].size;
        location.x = point.x - selfSize.width / 2.0f;
        location.y = point.y - selfSize.height / 2.0f;
        [self fadeIn];
    }
}

- (void)fadeIn
{
    if (!visible) {
        visible = YES;

        float statusBarHeight = [UIHardware statusBarHeight];
        CGSize superSize = [[self superview] bounds].size;
        superSize.height -= statusBarHeight;

        [self setOrigin:CGPointMake(location.x, location.y + statusBarHeight)];
        [self setAlpha:0.0f];

        [UIView beginAnimations:@"fadeIn"];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:
                 @selector(animationDidStop:finished:context:)];
        [UIView setAnimationDuration:MENU_FADE_IN_TIME];
        [self setAlpha:0.5f];
        [UIView commitAnimations];
    }
}

- (void)hide
{
    if (visible) {
        [UIView beginAnimations:@"fadeOut"];
        [UIView setAnimationDuration: MENU_FADE_OUT_TIME];
        [self setAlpha:0];
        [UIView endAnimations];

        visible = NO;
    }
    [self setDelegate:nil];
}

#pragma mark Animation-related delegate methods

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    if ([animationID isEqualToString:@"fadeIn"] && [finished boolValue] == YES)
        if ([delegate respondsToSelector:@selector(pieDidAppear)])
            [delegate performSelector:@selector(pieDidAppear)];
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
