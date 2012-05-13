//
//  Color.h
//  Terminal

#import <UIKit/UIColor.h>

UIColor *colorWithRGBA(float red, float green, float blue, float alpha);

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface UIColor(ArraySupport)

+ (UIColor *)colorWithArray:(NSArray *)array;
- (id)initWithArray:(NSArray *)array;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface NSArray(ColorSupport)

+ (NSArray *)arrayWithColor:(UIColor *)color;
- (id)initWithColor:(UIColor *)color;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
