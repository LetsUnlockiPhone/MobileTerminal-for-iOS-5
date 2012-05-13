#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PreferencesGroup;

@interface PreferencesDataSource : NSObject
{
    NSMutableArray *groups;
}

- (id)init;
- (void)addGroup:(PreferencesGroup *)group;
- (PreferencesGroup *)groupAtIndex:(int)index;
- (int)groups;

- (int)numberOfGroupsInPreferencesTable:(UIPreferencesTable *)table;
- (int)preferencesTable:(UIPreferencesTable *)table numberOfRowsInGroup:(int)group;
- (UIPreferencesTableCell *)preferencesTable:(UIPreferencesTable *)table cellForGroup:(int)group;
- (float)preferencesTable:(UIPreferencesTable *)table heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposed;
- (UIPreferencesTableCell *)preferencesTable:(UIPreferencesTable *)table cellForRow:(int)row inGroup:(int)group;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
