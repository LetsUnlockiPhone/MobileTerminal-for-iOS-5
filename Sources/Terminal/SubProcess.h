// SubProcess.h

#import <Foundation/Foundation.h>

@protocol InputDelegateProtocol

- (void)handleStreamOutput:(const char *)c length:(unsigned int)len identifier:(int)tid;

@end

@interface SubProcess : NSObject
{
    int fd;
    id delegate;
    int termid;
    pid_t pid;
    int closed;
}

// Delegate should support InputDelegateProtocol
- (id)initWithDelegate:(id)inputDelegate identifier:(int)termid;
- (void)dealloc;
- (void)closeSession;
- (void)close;
- (BOOL)isRunning;
- (int)write:(const char *)c length:(unsigned int)len;
- (void)startIOThread:(id)inputDelegate;
- (void)failure:(NSString *)message;
- (void)setWidth:(int)width height:(int)height;
- (void)setIdentifier:(int)termid;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
