// PTYTextView.m

#define DEBUG_ALLOC 0
#define DEBUG_METHOD_TRACE 0

#import "PTYTextView.h"

#import <UIKit/NSString-UIStringDrawing.h>

#import "ColorMap.h"
#import "Log.h"
#import "MobileTerminal.h"
#import "Settings.h"
#import "VT100Screen.h"

#define DEBUGLOG NO

#define MAX_GLYPHS 256

//FIXME: put these in a standard header somewhere
extern CGFontRef CGContextGetFont(CGContextRef);
bool CGFontGetGlyphsForUnichars(CGFontRef, unichar[], CGGlyph[], size_t);


@implementation PTYTile

- (void)drawRect:(CGRect)rect
{
    [[self superview] drawTileFrame:[self frame] tileRect:rect];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation PTYTiledView

+ (Class)tileClass
{
    return [PTYTile class];
}

- (id)initWithFrame:(CGRect)frame
             source:(VT100Screen *)screen
           scroller:(UIScroller *)scroller
         identifier:(int)identifier
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setPositionsTilesFromOrigin:YES];
        [self setTileOrigin:CGPointMake(0,0)];

        termid = identifier;
        dataSource = screen;
        textScroller = scroller;

        [self refresh];

        // Create one tile per row
        CGSize size = CGSizeMake(480, lineHeight);
        [self setTileSize:size];
        [self setFirstTileSize:size];

        [self setOpaque:YES];
        [self setTilingEnabled:YES];
        [self setTileDrawingEnabled:YES];
    }
    return self;
}

- (void)dealloc
{
    CFRelease(fontRef);
    [super dealloc];
}

#pragma mark Other

- (void)resetFont
{
    fontRef = nil;
    [self refresh];
}

- (void)setSource:(VT100Screen *)screen
{
    dataSource = screen;
    [self updateAll];
    [self updateAndScrollToEnd];
}

- (CGRect)rectForRow:(int)row
{
    return CGRectMake(0, row * lineHeight, self.frame.size.width, lineHeight);
}

#pragma mark Screen update methods

- (void)updateAll
{
    [dataSource acquireLock];
    int height = [dataSource height];
    int lines = [dataSource numberOfLines];

    // Expand the height, and cause scroll
    int newHeight = lines * lineHeight;
    CGRect frame = [self frame];
    if (frame.size.height != newHeight) {
        frame.size.height = newHeight;
        [self setFrame:frame];
        [textScroller setContentSize:frame.size];
    }
    int startIndex = 0;
    if (lines > height)
        startIndex = lines - height;

    // Check for dirty on-screen rows; scroll back is not updated
    for (int row = 0; row < height; row++) {
        CGRect rect = CGRectMake(0, (startIndex + row) * lineHeight,
                [self frame].size.width, lineHeight);
        [self setNeedsDisplayInRect:rect];
    }

    [dataSource resetDirty];
    [dataSource releaseLock];
}

- (void)updateIfNecessary
{
    [dataSource acquireLock];
    int width = [dataSource width];
    int height = [dataSource height];
    int lines = [dataSource numberOfLines];

    CGRect frame = [self frame];
    float newHeight = lines * lineHeight;
    float oldHeight = frame.size.height;

    if (oldHeight != newHeight) {
        // expand height -> refresh
        frame.size.height = newHeight;
        [self setFrame:frame];
        [textScroller setContentSize:frame.size];

        [self removeAllTiles];
        [self setNeedsDisplay];
    } else if (lines >= 1000) {
        // scrollback buffer full -> refresh
        [self removeAllTiles];
        [self setNeedsDisplay];
    } else {
        // redraw dirty lines
        int row, column, startIndex = MAX(0, lines - height);

        for (row = 0; row < height; row++) {
            const char *dirty = [dataSource dirty] + row * width;
            for (column = 0; column < width; column++) {
                if (dirty[column]) {
                    CGRect rect = CGRectMake(0, (startIndex + row) * lineHeight, [self frame].size.width, lineHeight);
                    [self setNeedsDisplayInRect:rect];
                    break;
                }
            }
        }
    }

    [dataSource resetDirty];
    [dataSource releaseLock];
}

- (void)updateAndScrollToEnd
{
    [self updateIfNecessary];

    [dataSource acquireLock];
    CGRect visibleRect = CGRectMake(0, [self frame].size.height, 0, 0);
    [textScroller scrollRectToVisible:visibleRect animated:YES];
    [dataSource releaseLock];
}

- (void)refresh
{
    CGRect frame = [self frame];

    TerminalConfig *config = [TerminalConfig configForTerminal:termid];
    lineHeight = [config fontSize] + TERMINAL_LINE_SPACING;
    charWidth = [config fontSize] * [config fontWidth];

    [self setFirstTileSize:CGSizeMake(frame.size.width, lineHeight)];
    [self setTileSize:CGSizeMake(frame.size.width, lineHeight)];
    [self setNeedsLayout];
}

- (void)refreshCursorRow
{
    int row = [dataSource numberOfLines] - [dataSource height] + [dataSource cursorY];
    [self setNeedsDisplayInRect:CGRectMake(0, row *lineHeight, self.frame.size.width, lineHeight)];
}

#pragma mark Keyboard delegate methods

- (void)willSlideOut
{
    scrollOffset = [textScroller offset];
}

- (void)willSlideIn
{
    [textScroller setOffset:scrollOffset];
}

#pragma mark Font-related methods

- (void)setupTextForContext:(CGContextRef)context
{
    if (!fontRef) {
        TerminalConfig *config = [TerminalConfig configForTerminal:termid];
        const char *font = [config.font UTF8String];
        // First time through: cache the fontRef. This lookup is expensive.
        fontSize = config.fontSize;
        CGContextSelectFont(context, font, floor(lineHeight), kCGEncodingMacRoman);
        fontRef = CGContextGetFont(context);
        if (fontRef != NULL)
            fontRef = (CGFontRef)CFRetain(fontRef);
    } else
        CGContextSetFont(context, fontRef);
    CGContextSetFontSize(context, fontSize);

    CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    CGContextSetTextDrawingMode(context, kCGTextFill);

    // Flip text, for some reason it's written upside down by default
    // FIXME: determine the reason for this
    CGAffineTransform translate = CGAffineTransformMake(1, 0, 0, -1, 0, 1.0);
    CGContextSetTextMatrix(context, translate);
}

#pragma mark Drawing methods

- (void)drawBox:(CGContextRef)context color:(CGColorRef)color boxRect:(CGRect)rect
{
    const float *components = CGColorGetComponents(color);
    CGContextSetRGBFillColor(context, components[0], components[1],
            components[2], components[3]);
    CGContextFillRect(context, rect);
}

- (void)drawChars:(CGContextRef)context characters:(unichar *)characters
            count:(int)count color:(CGColorRef)color point:(CGPoint)point
{
    const float *components = CGColorGetComponents(color);
    CGContextSetRGBFillColor(context, components[0], components[1],
            components[2], components[3]);
    // TODO: Consider adjusting the text point based on the rotation above

    // Use CGContextShowGlyphsWithAdvances() and make up the advances.

    //Get the glyphs
    CGGlyph glyphs[MAX_GLYPHS] = { 0 };
    CGSize advances[MAX_GLYPHS];
    // don't overflow the buffer - should never be an issue
    if (count > MAX_GLYPHS)
        count = MAX_GLYPHS;
    for (int i = 0; i<count; i++)
        advances[i] = CGSizeMake(charWidth, 0.0);
    CGFontGetGlyphsForUnichars(fontRef, characters, glyphs, count);

    //plot the glyphs
    CGContextSetTextPosition(context, floor(point.x), floor(point.y));
    CGContextShowGlyphsWithAdvances(context, glyphs, advances, count);
}

- (void)drawTileFrame:(CGRect)frame tileRect:(CGRect)rect
{
    // Each Tile is responsible for one row so determine the row that this
    // tile is responsible for based on its bounding rectangle.
    int row = (int)((frame.origin.y - [self frame].origin.y) / lineHeight);
    if (row >= 0 && rect.size.height == lineHeight)
        [self drawRow:row tileRect:(CGRect)rect];
}

- (void)drawRow:(unsigned int)row tileRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    [dataSource acquireLock];

    CGRect charRect = CGRectMake(rect.origin.x, rect.origin.y, charWidth, lineHeight);

    // Draw background for each column in the row
    int width = [dataSource width];
    int column;

    screen_char_t *theLine = [dataSource getLineAtIndex:row];

    // Avoid painting each black square individually. First paint the whole
    // row with the background color

    [self drawBox:context
            color:[[[ColorMap sharedInstance] colorForCode:BG_COLOR_CODE termid:termid] CGColor]
          boxRect:CGRectMake(rect.origin.x, rect.origin.y, charWidth *width, lineHeight)];

    // now specially paint any exceptional backgrounds
    unsigned int col1 = 0, bg1 = theLine[0].bg_color;
    for (column = 1; column < width; column++) {
        unsigned int bgcode = theLine[column].bg_color;
        if (bgcode != bg1) {
            charRect.size.width = charWidth * (column - col1);
            if (bg1 != BG_COLOR_CODE) {
                UIColor *bg = [[ColorMap sharedInstance] colorForCode:bg1 termid:termid];
                [self drawBox:context color:[bg CGColor] boxRect:charRect];
            }
            charRect.origin.x += charRect.size.width;
            bg1 = bgcode;
            col1 = column;
        }
    }
    charRect.size.width = charWidth * (column - col1);
    if (bg1 != BG_COLOR_CODE) {
        UIColor *bg = [[ColorMap sharedInstance] colorForCode:bg1 termid:termid];
        [self drawBox:context color:[bg CGColor] boxRect:charRect];
    }

    // Fill a rectangle with the cursor. drawRow consideres scrollback buffer;
    // cursorY is relative to the non-scrollback screen.
    int cursorY = [dataSource cursorY];
    int cursorX = [dataSource cursorX];
    if ([dataSource numberOfLines] > [dataSource height])
        cursorY += ([dataSource numberOfLines] - [dataSource height]);
    unsigned int cursorSaveColor = 0;

    if (row == cursorY) {
        CGRect cursorRect = CGRectMake(rect.origin.x, rect.origin.y, charWidth, lineHeight);
        cursorRect.origin.x += cursorX * charWidth;
        BOOL ctrlMode = [[MobileTerminal application] controlKeyMode];

        UIColor *cursorColor = [[ColorMap sharedInstance]
            colorForCode:(ctrlMode ? CURSOR_TEXT : CURSOR_BG)termid:termid];
        [self drawBox:context color:[cursorColor CGColor] boxRect:cursorRect];

        cursorSaveColor = theLine[cursorX].fg_color;
        theLine[cursorX].fg_color = ctrlMode ? CURSOR_BG : CURSOR_TEXT;
    }

    // Set font and mirror text; start one line lower to account for text flip
    [self setupTextForContext:context];
    // TODO: Text adjustment (3 px) should be font line height dependent. Needs
    // some testing.
    charRect.origin.y += lineHeight - 3;

    // Draw foreground character for each column in the row
    charRect.origin.x = rect.origin.x;
    col1 = 0;
    unsigned int fg1 = theLine[0].fg_color;
    unichar characters[MAX_GLYPHS] = {0};
    int n = (width < MAX_GLYPHS) ? width : MAX_GLYPHS;
    for (column = 0; column < n; column++) {
        unichar c = theLine[column].ch;
        if (c == 0)
            c = ' ';
        characters[column] = c;
    }
    for (column = 0; column < n; column++) {
        unsigned int fgcode = theLine[column].fg_color;
        if (fgcode != fg1) {
            UIColor *fg = [[ColorMap sharedInstance] colorForCode:fg1 termid:termid];
            [self drawChars:context characters:(characters + col1) count:(column - col1)
                      color:[fg CGColor] point:charRect.origin];
            charRect.origin.x += charWidth * (column - col1);
            fg1 = fgcode;
            col1 = column;
        }
    }
    UIColor *fg = [[ColorMap sharedInstance] colorForCode:fg1 termid:termid];
    [self drawChars:context characters:characters+col1 count:(n-col1)color:[fg CGColor] point:charRect.origin];

    if (row == cursorY)
        theLine[cursorX].fg_color = cursorSaveColor;

    [dataSource releaseLock];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation PTYTextView

@synthesize tiledView;

- (id)initWithFrame:(CGRect)frame source:(VT100Screen *)screen
    identifier:(int)identifier
{
    self = [super init];
    if (self) {
        terminalId = identifier;
        tiledView = [[PTYTiledView alloc] initWithFrame:frame
            source:screen scroller:self identifier:identifier];
        [self addSubview:tiledView];

        [self setAllowsRubberBanding:NO];
        [self setBottomBufferHeight:0.0];
        [self setBounces:YES];
        [self setContentSize:[tiledView bounds].size];
        [self setScrollerIndicatorStyle:2];
        [self displayScrollerIndicators];
        [self setAdjustForContentSizeChange:YES];
    }
    return self;
}

- (void)dealloc
{
    [tiledView release];
    [super dealloc];
}

// FIXME: due to a bug in VT100Screen, overriding setFrame causes the program
//        to crash at startup. For now, we use a different method name.
- (void)updateFrame:(CGRect)frame
{
    TerminalConfig *config = [TerminalConfig configForActiveTerminal];

    // Calculate text parameters
    float lineHeight = [config fontSize] + TERMINAL_LINE_SPACING;
    float charWidth = [config fontSize] * [config fontWidth];
    int rows = frame.size.height / lineHeight;
    int columns = [config autosize] ? frame.size.width / charWidth : [config width];

    // Adjust the content view
    [tiledView setFrame:CGRectMake(0, 0, columns * charWidth, rows * lineHeight)];

    [super setFrame:frame];
    [self setContentSize:[tiledView bounds].size];

    Terminal *terminal = [[MobileTerminal application] activeTerminal];
    [terminal.process setWidth:columns height:rows];
    [terminal.screen resizeWidth:columns height:rows];
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
