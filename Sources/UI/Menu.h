//
// Menu.h
// Terminal

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIThreePartButton.h>
#import <UIKit/UITouch.h>
#import <UIKit/UIView.h>

#import "Constants.h"
#import "Tools.h"

@class Menu;

@interface MenuItem : NSObject
{
    Menu *menu;
    Menu *submenu;
    NSString *title;
    NSString *command;

    id delegate;
}

@property(nonatomic, readonly) Menu *menu;
@property(nonatomic, retain) Menu *submenu;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *command;
@property(nonatomic, copy) NSString *commandString;
@property(nonatomic, assign) id delegate;

- (id)initWithMenu:(Menu *)menu;

- (BOOL)hasSubmenu;
- (int)index;
- (NSDictionary *)getDict;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface Menu : NSObject
{
    NSMutableArray *items;
    NSString *dot;
}

@property(nonatomic, readonly) NSArray *items;

+ (Menu *)menu;
+ (Menu *)menuWithArray:(NSArray *)array;

- (id)init;
- (NSArray *)getArray;
- (int)indexOfItem:(MenuItem *)item;
- (MenuItem *)itemAtIndex:(int)index;
- (NSString *)dotStringWithCommand:(NSString *)command;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface MenuButton : UIThreePartButton
{
    MenuItem *item;
}

@property(nonatomic, retain) MenuItem *item;

- (BOOL)isMenuButton;
- (BOOL)isNavigationButton;
- (void)update;
- (void)menuItemChanged:(MenuItem *)menuItem;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface MenuView : UIView
{
    MenuButton *activeButton;
    NSMutableArray *history;

    CGPoint location;

    BOOL tapMode;
    BOOL visible;
    BOOL activated;
    BOOL showsEmptyButtons;

    id delegate;
}

@property(nonatomic) BOOL tapMode;
@property(nonatomic, readonly, getter=isVisible) BOOL visible;
@property(nonatomic, getter=isActivated) BOOL activated;
@property(nonatomic) BOOL showsEmptyButtons;
@property(nonatomic, assign) id delegate;

+ (MenuView *)sharedInstance;

- (void)handleTrackingAt:(CGPoint)point;
- (NSString *)handleTrackingEnd;

- (void)loadMenu;
- (void)loadMenu:(Menu *)menu;
- (void)pushMenu:(Menu *)menu;
- (void)popMenu;

- (MenuButton *)buttonAtIndex:(int)index;
- (void)selectButton:(MenuButton *)button;
- (void)deselectButton:(MenuButton *)button;

- (void)showAtPoint:(CGPoint)point;
- (void)fadeIn;
- (void)hide;
- (void)hideSlow:(BOOL)slow;

- (void)buttonPressed:(id)button;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
