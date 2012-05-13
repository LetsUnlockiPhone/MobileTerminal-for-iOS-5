#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CGGeometry.h>
#include <Foundation/Foundation.h>

#define logf(s,...) [FileLog logFile:__FILE__ lineNumber:__LINE__ format:(s),##__VA_ARGS__]
#define logfRect(s, r) [FileLog logFile:__FILE__ lineNumber:__LINE__ string:(s)rect:(r)]
#define log(s,...) [FileLog logFunc:__PRETTY_FUNCTION__ format:(s),##__VA_ARGS__]
#define logRect(s, r) [FileLog logFunc:__PRETTY_FUNCTION__ string:(s)rect:(r)]
#define logPoint(s, p) [FileLog logFunc:__PRETTY_FUNCTION__ string:(s)point:(p)]

@interface FileLog : NSObject

+ (void)logFunc:(const char *)func format:(NSString *)format, ...;
+ (void)logFunc:(const char *)func string:(NSString *)s rect:(CGRect)r;
+ (void)logFunc:(const char *)func string:(NSString *)s point:(CGPoint)p;
+ (void)logFile:(char *)sourceFile lineNumber:(int)lineNumber format:(NSString *)format, ...;
+ (void)logFile:(char *)sourceFile lineNumber:(int)lineNumber string:(NSString *)s rect:(CGRect)r;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
