#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIPreferencesTextTableCell.h>

#import "Color.h"
#import "ColorWidgets.h"


@interface TextTableCell : UIPreferencesTextTableCell
{
    SEL textChangedAction;
}

@property(nonatomic, assign) SEL textChangedAction;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________


@interface ColorPageButtonCell : UIPreferencesTextTableCell
{
    ColorSquare *colorSquare;
}

@property(nonatomic, readonly) ColorSquare *colorSquare;

- (id)initWithFrame:(CGRect)frame colorRef:(UIColor **)colorRef_;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface PreferencesGroup : NSObject
{
    UIPreferencesTableCell *title;
    NSMutableArray *cells;
    NSMutableArray *keys;
    float titleHeight;
    int tag;
}

@property(readwrite) float titleHeight;
@property(readonly) UIPreferencesTableCell *title;

+ (id)groupWithTitle:(NSString *)title icon:(UIImage *)icon;
- (id)initWithTitle:(NSString *)title icon:(UIImage *)icon;
- (void)addCell:(id)cell;
- (void)removeCell:(id)cell;

- (id)addSwitch:(NSString *)label;
- (id)addSwitch:(NSString *)label target:(id)target action:(SEL)action;
- (id)addSwitch:(NSString *)label on:(BOOL)on;
- (id)addSwitch:(NSString *)label on:(BOOL)on target:(id)target action:(SEL)action;

- (id)addIntValueSlider:(NSString *)label range:(NSRange)range target:(id)target action:(SEL)action;
- (id)addFloatValueSlider:(NSString *)label minValue:(float)minValue maxValue:(float)maxValue target:(id)target action:(SEL)action;

- (id)addPageButton:(NSString *)label;
- (id)addColorPageButton:(NSString *)label colorRef:(UIColor **)color;
- (id)addValueField:(NSString *)label value:(NSString *)value;

- (id)addTextField:(NSString *)label value:(NSString *)value;
- (id)addColorField;

- (int)rows;
- (BOOL)boolValueForRow:(int)row;
- (UIPreferencesTableCell *)row:(int)row;
- (NSString *)stringValueForRow:(int)row;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
