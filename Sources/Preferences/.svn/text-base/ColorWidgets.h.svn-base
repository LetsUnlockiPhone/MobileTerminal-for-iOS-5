#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Color.h"

@interface ColorSquare : UIView
{
    UIColor **colorRef;
}

@property(nonatomic, retain) UIColor *color;

- (id)initWithFrame:(CGRect)frame colorRef:(UIColor **)c;
- (void)colorChanged:(NSArray *)colorValues;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface ColorTableCell : UIPreferencesTableCell
{
    UIColor *color;
}

@property(nonatomic, retain) UIColor *color;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
