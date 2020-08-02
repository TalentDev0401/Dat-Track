//
//  MultipartRequest.h
//

#import <UIKit/UIKit.h>


@interface GeneralMultipartRequest : NSObject {
	NSMutableArray *fields;
    NSMutableDictionary* binaryFields; // key: field-name (NSString*)  value: NSArray(NSData*, mime-type(NSString*))
	NSURL *url;
}
- (NSString *)getURL;
- (NSArray *)getFields;
- (NSDictionary *)getBinaryFields;
- (id)initWithURL:(NSURL *)url;
- (void)addValue:(id)v forField:(NSString *)f;
- (void)addValue:(NSData *)v forField:(NSString *)f mimeType:(NSString *)mimeType;
- (NSURLRequest *)urlRequest;

@end
