//
//  Preferences.h
//  Terminal

#import <UIKit/UIKit.h>

@class MobileTerminal;

@interface PreferencesController : UINavigationController 
{
    int terminalIndex;
}

@property(nonatomic) int terminalIndex;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
