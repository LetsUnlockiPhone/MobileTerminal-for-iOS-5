//
// Tools.h
// Terminal

#import <CoreGraphics/CGImage.h>
#import <Foundation/Foundation.h>

BOOL writeImageToPNG (CGImageRef image, NSString *filePath);

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface NSArray (NSFastEnumeration)

- (int)countByEnumeratingWithState:(void *)state objects:(id *)stackbuf count:(int)len;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface NSString (MobileTerminalExtensions)

- (int)indexOfSubstring:(NSString *)substring;
- (BOOL)hasSubstring:(NSString *)substring;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface NSMutableString (MobileTerminalExtensions)

- (void)removeSubstring:(NSString *)substring;

@end

 /* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
