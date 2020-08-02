//
//  NSData+Compression.h
//  rpm
//
//  Extracted from http://cocoadev.com/wiki/NSDataCategory
//
//

#import <Foundation/Foundation.h>

@interface NSData (Compression)

// ZLIB
- (NSData *) zlibInflate;
- (NSData *) zlibDeflate;
- (NSString *)getRandomBoundary;

@end
