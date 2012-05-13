// ColorMap.m

#import "ColorMap.h"

#import "Color.h"
#import "VT100Terminal.h"


static UIColor *initWithRGB(float red, float green, float blue)
{
    return [[UIColor alloc] initWithRed:red green:green blue:blue alpha:1];
}

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation ColorMap

+ (ColorMap *)sharedInstance
{
    static ColorMap *instance = nil;
    if (instance == nil) instance = [[[ColorMap alloc] init] retain];
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        // System 7.5 colors, why not?
        table[0] = initWithRGB( 0, 0, 0); // dark black
        table[1] = initWithRGB(0.6, 0, 0); // darkRed
        table[2] = initWithRGB( 0, 0.6, 0); // darkGreen
        table[3] = initWithRGB(0.6, 0.4, 0); // darkYellow
        table[4] = initWithRGB( 0, 0, 0.6); // darkBlue
        table[5] = initWithRGB(0.6, 0, 0.6); // darkMagenta
        table[6] = initWithRGB( 0, 0.6, 0.6); // darkCyan
        table[7] = initWithRGB(0.6, 0.6, 0.6); // darkWhite
        table[8] = initWithRGB(0, 0, 0); // black
        table[9] = initWithRGB(1, 0, 0); // red
        table[10] = initWithRGB(0, 1, 0); // green
        table[11] = initWithRGB(1, 1, 0); // yellow
        table[12] = initWithRGB(0, 0, 1); // blue
        table[13] = initWithRGB(1, 0, 1); // magenta
        table[14] = initWithRGB(0, 1, 1); // lcyan
        table[15] = initWithRGB(1, 1, 1); // white

        int i;
        for (i = 0; i < MAX_TERMINALS; i++) {
            int ti = i *NUM_TERMINAL_COLORS;
            switch (i) { // bg color
                case 1: table[BG_COLOR+ti] = initWithRGB(0.1, 0, 0); break;
                case 2: table[BG_COLOR+ti] = initWithRGB(0, 0, 0.1); break;
                case 3: table[BG_COLOR+ti] = initWithRGB(0, 0.1, 0); break;
                default: table[BG_COLOR+ti] = initWithRGB(0, 0, 0); break;
            }
            table[FG_COLOR+ti] = initWithRGB(1, 1, 1); // fg color
            table[FG_COLOR_BOLD+ti] = initWithRGB(1, 1, 0); // bold color
            table[FG_COLOR_CURSOR+ti] = initWithRGB(1, 0, 0); // cursor text color
            table[BG_COLOR_CURSOR+ti] = initWithRGB(1, 1, 0); // cursor color
        }
    }
    return self;
}

- (void)dealloc
{
    int i;
    for (i = 0; i < NUM_COLORS; i++) [table[i] release];
    [super dealloc];
}

- (void)setTerminalColor:(UIColor *)color atIndex:(int)index termid:(int)termid
{
    int i = BG_COLOR + termid *NUM_TERMINAL_COLORS + index;
    if (table[i] != color) {
        [table[i] release];
        table[i] = [color retain];
    }
}

- (UIColor *)colorForCode:(unsigned int)index termid:(int)termid
{
    UIColor *color;

    int ti = termid *NUM_TERMINAL_COLORS;
    if (index & COLOR_CODE_MASK) // special color?
    {
        switch (index) {
            case CURSOR_TEXT:
                color = table[FG_COLOR_CURSOR+ti];
                break;
            case CURSOR_BG:
                color = table[BG_COLOR_CURSOR+ti];
                break;
            case BG_COLOR_CODE:
                color = table[BG_COLOR+ti];
                break;
            default:
                if (index & BOLD_MASK)
                    color = (index-BOLD_MASK == BG_COLOR_CODE) ? table[BG_COLOR+ti] : table[FG_COLOR_BOLD+ti];
                else
                    color = table[FG_COLOR+ti];
                break;
        }
    } else {
        index &= 0xff;

        if (index < 16) {
            color = table[index];
        } else if (index < 232) {
            index -= 16;
            float components[] = {
                (index / 36) ? ((index / 36) * 40 + 55) / 256.0 : 0,
                (index % 36) / 6 ? (((index % 36) / 6) * 40 + 55 ) / 256.0 : 0,
                (index % 6) ? ((index % 6) * 40 + 55) / 256.0 : 0,
                1.0
            };
            color = colorWithRGBA(components[0], components[1], components[2], 1);
        } else {
            color = table[FG_COLOR+ti];
        }
    }
    return color;
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
