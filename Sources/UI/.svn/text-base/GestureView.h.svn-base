//
// GestureView.h
// Terminal

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIControl.h>


@class PieView;
@class MenuView;

struct GSPathPoint {
    char unk0;
    char unk1;
    short int status;
    int unk2;
    float x;
    float y;
};

typedef struct {
    int unk0;
    int unk1;
    int type;
    int subtype;
    float unk2;
    float unk3;
    float x;
    float y;
    int timestamp1;
    int timestamp2;
    int unk4;
    int modifierFlags;
    int unk5;
    int unk6;
    int mouseEvent;
    short int dx;
    short int fingerCount;
    int unk7;
    int unk8;
    char unk9;
    char numPoints;
    short int unk10;
    struct GSPathPoint points[10];
} GSEventStruct;

@protocol GestureInputProtocol

- (void)showPie:(CGPoint)point;
- (void)hidePie;
- (void)showMenu:(CGPoint)point;
- (void)hideMenu;
- (void)handleInputFromMenu:(NSString *)input;
- (void)toggleKeyboard;

@end

@interface GestureView : UIControl
{
    PieView *pieView;
    MenuView *menuView;

    CGPoint touchPos;

    id delegate;
    BOOL menuTapped;

    NSTimer *toggleKeyboardTimer;

    @private
        int fingersDown_;
        CGPoint touchInitialPoint_;
}

- (id)initWithFrame:(CGRect)rect delegate:(id)inputDelegate;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
