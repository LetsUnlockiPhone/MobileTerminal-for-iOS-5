#include "Log.h"

#define LOGFILE @"/Applications/Terminal.app/log"

@implementation FileLog

+ (void)initialize { }

+ (void)logStr:(NSString *)str
{
    NSLog(str);

    NSFileHandle *aFileHandle;
    NSString *aFile;

    aFile = [[NSString stringWithString:LOGFILE] stringByExpandingTildeInPath];

    aFileHandle = [NSFileHandle fileHandleForWritingAtPath:aFile];
    [aFileHandle truncateFileAtOffset:[aFileHandle seekToEndOfFile]];

    [aFileHandle writeData:[[NSString stringWithFormat: @"%@\n", str] dataUsingEncoding:kCFStringEncodingUTF8]];
}

+ (void)logFunc:(const char *)func format:(NSString *)format, ...;
{
    va_list ap;
    NSString *print, *funcs;

    va_start(ap,format);

    funcs=[[NSString alloc] initWithBytes:func length:strlen(func) encoding:NSUTF8StringEncoding];
    print=[[NSString alloc] initWithFormat:format arguments:ap];

    va_end(ap);

    NSString *str = [NSString stringWithFormat:@"%@: %@", funcs, print];

    [FileLog logStr:str];

    [print release];
    [funcs release];
}

+ (void)logFunc:(const char *)func string:(NSString *)s rect:(CGRect)r
{
    [FileLog logFunc: func format:@"%@ [%0.2f %0.2f %0.2f %0.2f]", s, r.origin.x, r.origin.y, r.size.width, r.size.height];
}

+ (void)logFunc:(const char *)func string:(NSString *)s point:(CGPoint)p
{
    [FileLog logFunc: func format:@"%@ <%0.2f %0.2f>", s, p.x, p.y];
}

+ (void)logFile:(char *)sourceFile lineNumber:(int)lineNumber format:(NSString *)format, ...;
{
    va_list ap;
    NSString *print,*file;

    va_start(ap,format);

    file=[[NSString alloc] initWithBytes:sourceFile length:strlen(sourceFile) encoding:NSUTF8StringEncoding];
    print=[[NSString alloc] initWithFormat:format arguments:ap];

    va_end(ap);

    NSString *str = [NSString stringWithFormat:@"%s:%d %@",[[file lastPathComponent] UTF8String], lineNumber, print];

    [FileLog logStr:str];

    [print release];
    [file release];
}

+ (void)logFile:(char *)sourceFile lineNumber:(int)lineNumber string:(NSString *)s rect:(CGRect)r
{
    [FileLog logFile: sourceFile lineNumber:lineNumber format:@"%@ [%0.2f %0.2f %0.2f %0.2f]", s, r.origin.x, r.origin.y, r.size.width, r.size.height];
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
