#import "PreferencesDataSource.h"

#import "PreferencesGroup.h"

@implementation PreferencesDataSource

- (id)init
{
    if ((self = [super init])) {
        groups = [[NSMutableArray arrayWithCapacity:1] retain];
    }

    return self;
}

- (void)addGroup:(PreferencesGroup *)group
{
    [groups addObject:group];
}

- (PreferencesGroup *)groupAtIndex:(int)index
{
    return [groups objectAtIndex:index];
}

- (int)groups
{
    return [groups count];
}

- (int)numberOfGroupsInPreferencesTable:(UIPreferencesTable *)table
{
    return [groups count];
}

- (int)preferencesTable:(UIPreferencesTable *)table numberOfRowsInGroup:(int)group
{
    return [[groups objectAtIndex:group] rows];
}

- (UIPreferencesTableCell *)preferencesTable:(UIPreferencesTable *)table cellForGroup:(int)group
{
    return [[groups objectAtIndex:group] title];
}

- (float)preferencesTable:(UIPreferencesTable *)table heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposed
{
    if (row == -1) {
        return [[groups objectAtIndex:group] titleHeight];
    } else {
        UIPreferencesTableCell *cell = [[groups objectAtIndex:group] row:row];
        if ([cell respondsToSelector:@selector(getHeight)]) {
            float height;
            SEL sel = @selector(getHeight);
            NSMethodSignature *sig = [[cell class] instanceMethodSignatureForSelector:sel];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
            [invocation setTarget:cell];
            [invocation setSelector:sel];
            [invocation invoke];
            [invocation getReturnValue:&height];
            return height;
        } else
            return proposed;
    }
}

- (UIPreferencesTableCell *)preferencesTable:(UIPreferencesTable *)table cellForRow:(int)row inGroup:(int)group
{
    return [[groups objectAtIndex:group] row:row];
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
