// PTYTextView.h
//
// PTYTextView contains a PTYTiledView that creates PTYTiles, which call back to
// PTYTiledView when they  are asked to be drawn.

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIScroller.h>
#import <UIKit/UITile.h>
#import <UIKit/UITiledView.h>


@class VT100Screen;

@interface PTYTile : UITile

- (void)drawRect:(CGRect)rect;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface PTYTiledView : UITiledView
{
    // geometry
    float lineHeight;
    float lineWidth;
    float charWidth;
    int numberOfLines;

    int termid;

    // data source
    VT100Screen *dataSource;
    UIScroller *textScroller;

    CGPoint scrollOffset;

    // cached font details
    CGFontRef fontRef;
    float fontSize;
}

+ (Class)tileClass;

- (id)initWithFrame:(CGRect)frame source:(VT100Screen *)screen
    scroller:(UIScroller *)scroller identifier:(int)identifier;
- (void)dealloc;

- (void)setSource:(VT100Screen *)screen;
- (void)updateAll;

- (void)drawTileFrame:(CGRect)frame tileRect:(CGRect)rect;
- (void)drawRow:(unsigned int)row tileRect:(CGRect)rect;
- (void)refresh;
- (void)refreshCursorRow;
- (void)resetFont;

- (void)updateIfNecessary;
- (void)updateAndScrollToEnd;

- (void)willSlideIn;
- (void)willSlideOut;

- (void)drawBox:(CGContextRef)context color:(CGColorRef)color boxRect:(CGRect)rect;

- (void)drawChars:(CGContextRef)context characters:(unichar *)characters count:(int)count color:(CGColorRef)color point:(CGPoint)point;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface PTYTextView : UIScroller
{
    PTYTiledView *tiledView;
    int terminalId;
}

@property(nonatomic, readonly) PTYTiledView *tiledView;

- (id)initWithFrame:(CGRect)frame source:(VT100Screen *)screen
    identifier:(int)identifier;
- (void)updateFrame:(CGRect)frame;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
