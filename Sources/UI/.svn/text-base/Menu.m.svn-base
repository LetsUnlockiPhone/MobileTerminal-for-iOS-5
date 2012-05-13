//
// Menu.m
// Terminal

#import "Menu.h"

#import <UIKit/UIControl-UIControlPrivate.h>
#import <UIKit/UIGradient.h>

#import "GestureView.h"
#import "Log.h"
#import "MobileTerminal.h"
#import "Settings.h"

#define NUM_OF_ROWS 4
#define NUM_OF_COLS 3

#define NUM_OF_BUTTONS (NUM_OF_ROWS * NUM_OF_COLS)

#define MENU_WIDTH (NUM_OF_COLS * MENU_BUTTON_WIDTH)
#define MENU_HEIGHT (NUM_OF_ROWS * MENU_BUTTON_HEIGHT)


@implementation MenuItem

@synthesize menu;
@synthesize submenu;
@synthesize title;
@synthesize command;
@synthesize delegate;

- (id)initWithMenu:(Menu *)menu_
{
    self = [super init];
    if (self) {
        menu = menu_;
        // NOTE: leaving title and command as nil causes problems in getDict
        title = @"";
        command = @"";
    }
    return self;
}

#pragma mark Other

- (BOOL)hasSubmenu
{
    return (submenu != nil);
}

- (int)index
{
    return [menu indexOfItem:self];
}

- (NSDictionary *)getDict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];

    [dict setObject:title forKey:MENU_TITLE];
    [dict setObject:command forKey:MENU_CMD];
    if (submenu)
        [dict setObject:[submenu getArray] forKey:MENU_SUBMENU];

    return dict;
}

- (void)notifyDelegate
{
    if ([delegate respondsToSelector:@selector(menuItemChanged:)])
       [delegate performSelector:@selector(menuItemChanged:) withObject:self];
}

#pragma mark Properties

- (void)setTitle:(NSString *)title_
{
    if (title != title_) {
        [title release];
        title = [title_ copy];
        [self notifyDelegate];
    }
}

- (void)setCommand:(NSString *)command_
{
    if (command != command_) {
        [command release];
        command = [command_ copy];
        [self notifyDelegate];
    }
}

static NSMutableString *convertCommandString(Menu *menu, NSString *cmd, BOOL isCommand)
{
    NSMutableString *s = [NSMutableString stringWithCapacity:64];
    [s setString:cmd];

    int i = 0;
    while (STRG_CTRL_MAP[i].str) {
        int toLength = 0;
        while (STRG_CTRL_MAP[i].chars[toLength]) toLength++;
        NSString *from = [menu dotStringWithCommand:STRG_CTRL_MAP[i].str];
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
    return convertCommandString(menu, [self command], YES);
}

- (void)setCommandString:(NSString *)cmdString
{
    [self setCommand:convertCommandString(menu, cmdString, NO)];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation Menu

+ (Menu *)menu
{
    return [[[Menu alloc] init] autorelease];
}

+ (Menu *)menuWithArray:(NSArray *)array
{
    Menu *menu = [[Menu alloc] init];
    for (int i = 0; i < NUM_OF_BUTTONS; i++) {
        MenuItem *item = [[menu items] objectAtIndex:i];

        NSDictionary *dict = [array objectAtIndex:i];
        [item setTitle:[dict objectForKey:MENU_TITLE]];
        [item setCommand:[dict objectForKey:MENU_CMD]];

        NSArray *submenu = [dict objectForKey:MENU_SUBMENU];
        if (submenu)
            [item setSubmenu:[Menu menuWithArray:submenu]];
    }
    return [menu autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        items = [[NSMutableArray alloc] initWithCapacity:NUM_OF_BUTTONS];
        for (int i = 0; i < NUM_OF_BUTTONS; i++)
            [items addObject:[[MenuItem alloc] initWithMenu:self]];

        unichar dotChar[1] = {0x2022};
        dot = [[NSString alloc] initWithCharacters:dotChar length:1];
    }
    return self;
}

- (void)dealloc
{
    [dot release];
    [items release];

    [super dealloc];
}

#pragma mark Other

- (NSArray *)getArray
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:NUM_OF_BUTTONS];
    for (MenuItem *item in items)
        [array addObject:[item getDict]];
    return array;
}

- (MenuItem *)itemAtIndex:(int)index
{
    return [items objectAtIndex:index];
}

- (int)indexOfItem:(MenuItem *)item
{
    return [items indexOfObjectIdenticalTo:item];
}

- (NSString *)dotStringWithCommand:(NSString *)cmd
{
    return [NSString stringWithFormat:@"%@%@", dot, cmd];
}

#pragma mark Properties

- (NSArray *)items
{
    return items;
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation MenuButton

@synthesize item;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CDAnonymousStruct10 buttonPieces = {
                .left = { .origin = { .x = 0.0f, .y = 0.0f },
                    .size = { .width = 12.0f, .height = MENU_BUTTON_HEIGHT } },
                .middle = { .origin = { .x = 12.0f, .y = 0.0f },
                    .size = { .width = 20.0f, .height = MENU_BUTTON_HEIGHT } },
                .right = { .origin = { .x = 32.0f, .y = 0.0f },
                    .size = { .width = 12.0f, .height = MENU_BUTTON_HEIGHT } },
        };

        [self setDrawContentsCentered:YES];
        [self setBackgroundSlices:buttonPieces];
        [self setAutosizesToFit:NO];
        [self setEnabled:YES];
        [self setOpaque:NO];

        [self setTitleColor:[UIColor blackColor] forState:0]; // normal
        [self setTitleColor:[UIColor whiteColor] forState:1]; // pressed
        [self setTitleColor:[UIColor whiteColor] forState:4]; // selected
    }
    return self;
}

#pragma mark Other

- (BOOL)isMenuButton
{
    return ([item submenu] != nil);
}

- (BOOL)isNavigationButton
{
    return ([self isMenuButton] || [[item command]
        isEqualToString:[[item menu] dotStringWithCommand:@"back"]]);
}

- (void)update
{
    NSString *normalImage, *selectedImage;
    if ([self isNavigationButton]) {
        normalImage = @"menu_button_gray.png";
        selectedImage = @"menu_button_darkgray.png";
    } else {
        normalImage = @"menu_button_white.png";
        selectedImage = @"menu_button_blue.png";
    }
    [self setPressedBackgroundImage:[UIImage imageNamed:selectedImage]];
    [self setBackground:[UIImage imageNamed:selectedImage] forState:4];
    [self setBackgroundImage:[UIImage imageNamed:normalImage]];

    NSString *title = [item title];
    if (title == nil) title = [item command];
    if (title != nil) [self setTitle:title];
}

#pragma mark MenuItem delegate methods

- (void)menuItemChanged:(MenuItem *)menuItem
{
    if (item == menuItem)
        [self update];
}

#pragma mark Properties

- (void)setItem:(MenuItem *)item_
{
    item = item_;
    [item setDelegate:self];
    [self update];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation MenuView

@synthesize tapMode;
@synthesize visible;
@synthesize activated;
@synthesize showsEmptyButtons;
@synthesize delegate;

+ (MenuView *)sharedInstance
{
    static MenuView *instance = nil;
    if (instance == nil) {
        instance = [[MenuView alloc] init];
        [instance loadMenu];
    }
    return instance;
}

- (id)init
{
    self = [super initWithFrame:CGRectMake(0, 0,
            NUM_OF_ROWS * MENU_BUTTON_HEIGHT + 4,
            NUM_OF_COLS * MENU_BUTTON_WIDTH - 4)];
    if (self) {
        history = [[NSMutableArray alloc] initWithCapacity:5];
        visible = YES;
        [self setOpaque:NO];
    }
    return self;
}

- (void)dealloc
{
    [history release];
    [super dealloc];
}

- (void)drawRect:(struct CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    float w = rect.size.width;
    float h = rect.size.height;
    CGContextBeginPath (context);
    CGContextMoveToPoint(context, w/2, 0);
    CGContextAddArcToPoint(context, w, 0, w, h/2, 7);
    CGContextAddArcToPoint(context, w, h, w/2, h, 7);
    CGContextAddArcToPoint(context, 0, h, 0, h/2, 7);
    CGContextAddArcToPoint(context, 0, 0, w/2, 0, 7);
    CGContextClosePath (context);
    CGContextClip (context);

    float components[11] = { 0.5647f, 0.6f, 0.6275f, 1.0f, 0.0f,
        0.29f, 0.321f, 0.3651f, 1.0f, 1.0f, 0 };
    UIGradient *gradient = [[UIGradient alloc]
        initVerticalWithValues:(CDAnonymousStruct11 *)components];
    [gradient fillRect:rect];

    CGContextFlush(context);
}

#pragma mark Input from other views

- (void)handleTrackingAt:(CGPoint)point
{
    for (MenuButton *btn in [self subviews]) {
        //if ([btn isMenuButton] &&
        if (CGRectContainsPoint([btn frame], point)) {
            [self buttonPressed:btn];
            return;
        }
    }
    if (activeButton && ![activeButton isMenuButton]) {
        [activeButton setSelected:NO];
        activeButton = nil;
    }
}

- (NSString *)handleTrackingEnd
{
    [self hide];

    NSMutableString *command = nil;
    if (activeButton && ![activeButton isMenuButton]) {
        command = [NSMutableString stringWithCapacity:32];
        [command setString:[activeButton.item command]];
        [command removeSubstring:[[MobileTerminal menu] dotStringWithCommand:@"keepmenu"]];
        [command removeSubstring:[[MobileTerminal menu] dotStringWithCommand:@"back"]];
    }
    return command;
}

#pragma mark Menu-related methods

- (void)clearHistory
{
    [history removeAllObjects];
}

- (void)loadMenu
{
    [self clearHistory];
    [self pushMenu:[MobileTerminal menu]];
}

- (void)loadMenu:(Menu *)menu
{
    activeButton = nil;

    float x = 0.0f, y = 0.0f;

    for (UIView *view in [self subviews])
        [view removeFromSuperview];

    for (MenuItem *item in [menu items]) {
        MenuButton *button = nil;
        NSString *command = [item command];

        if (showsEmptyButtons || [item hasSubmenu] || (command != nil && [command length] > 0)) {
            CGRect buttonFrame = CGRectMake(x, y, MENU_BUTTON_WIDTH, MENU_BUTTON_HEIGHT);
            button = [[[MenuButton alloc] initWithFrame:buttonFrame] autorelease];
            [button setItem:item];
            [button addTarget:self action:@selector(buttonPressed:) forEvents:64];
            [self addSubview:button];
        }

        if ([item index] % NUM_OF_COLS == (NUM_OF_COLS - 1)) {
            x = 0.0f;
            y += MENU_BUTTON_HEIGHT;
        } else {
            x += MENU_BUTTON_WIDTH;
        }
    }
}

- (void)pushMenu:(Menu *)menu
{
    [history addObject:menu];
    [self loadMenu:menu];
}

- (void)popMenu
{
    if ([history count] > 1)
        [history removeLastObject];
    [self loadMenu:[history lastObject]];
}

#pragma mark Button-related methods

- (MenuButton *)buttonAtIndex:(int)index
{
    return [[self subviews] objectAtIndex:index];
}

- (void)selectButton:(MenuButton *)button
{
    [activeButton setSelected:NO];
    [button setSelected:YES];
    activeButton = button;
}

- (void)deselectButton:(MenuButton *)button
{
    [button setSelected:NO];
    if (button == activeButton)
        activeButton = nil;
}

- (void)buttonPressed:(id)button
{
    if (button != activeButton) {
        [self selectButton:button];
        if ([delegate respondsToSelector:@selector(menuButtonPressed:)])
            [delegate performSelector:@selector(menuButtonPressed:) withObject:activeButton];

        if ([activeButton isMenuButton]) {
            // Show submenu
            if ([delegate respondsToSelector:@selector(shouldLoadMenuWithButton:)])
                if (![delegate performSelector:@selector(shouldLoadMenuWithButton:) withObject:activeButton])
                    return;
            [self pushMenu:[activeButton.item submenu]];
        }
    }
}

#pragma mark Display-related methods

- (void)showAtPoint:(CGPoint)point
{
    if (!visible) {
        location.x = point.x;
        location.y = point.y;
        [self fadeIn];
    }
}

- (void)fadeIn
{
    if (!visible) {
        visible = YES;

        activeButton = nil;
        tapMode = NO;
        [self loadMenu];

        float statusBarHeight = [UIHardware statusBarHeight];
        CGSize superSize = [[self superview] bounds].size;
        superSize.height -= statusBarHeight;

        float lx = MIN(superSize.width - MENU_WIDTH,
                MAX(0, location.x - MENU_WIDTH / 2.0f));
        float ly = MIN(superSize.height - MENU_HEIGHT,
                MAX(0, location.y - 1.5f * MENU_BUTTON_HEIGHT));

        [self setTransform:CGAffineTransformMakeScale(1.0f, 1.0f)];
        [self setOrigin:CGPointMake(lx, ly + statusBarHeight)];
        [self setAlpha:0.0f];

        [UIView beginAnimations:@"fadeIn"];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:
                 @selector(animationDidStop:finished:context:)];
        [UIView setAnimationDuration:MENU_FADE_IN_TIME];
        [self setAlpha:1.0f];
        [UIView commitAnimations];
    }
}

- (void)hide
{
    [self hideSlow:NO];
    [self setDelegate:nil];
}

- (void)hideSlow:(BOOL)slow
{
    if (visible) {
        [UIView beginAnimations:@"fadeOut"];
        [UIView setAnimationDuration: slow ?
            MENU_SLOW_FADE_OUT_TIME : MENU_FADE_OUT_TIME];
        [self setTransform:CGAffineTransformMakeScale(0.01f, 0.01f)];
        [self setOrigin:CGPointMake(
            [self frame].origin.x + [self frame].size.width / 2,
            [self frame].origin.y + [self frame].size.height / 2)];
        [self setAlpha:0];
        [UIView endAnimations];

        visible = NO;
    }
}

#pragma mark Animation-related delegate methods

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    if ([animationID isEqualToString:@"fadeIn"] && [finished boolValue] == YES)
        if ([delegate respondsToSelector:@selector(menuFadedIn)])
            [delegate performSelector:@selector(menuFadedIn)];
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
