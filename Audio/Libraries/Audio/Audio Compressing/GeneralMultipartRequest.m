//
//  MultipartRequest.m
//

#import "GeneralMultipartRequest.h"
#include <stdio.h>

static NSString *kPrefix = @"HMMultiPartFormData";
#define kRandomPartLength		10

@implementation GeneralMultipartRequest

- (id)initWithURL:(NSURL *)u
{
	if( (self = [super init]) ) {
		fields = [[NSMutableArray alloc] init];
		binaryFields = [[NSMutableDictionary alloc] init];
		url = [u retain];
	}
	return self;
}

- (void)dealloc
{
	[url release];
    [binaryFields release];
	[fields release];
	[super dealloc];
}

- (NSString *)getURL {
    return url.path;
}

- (NSArray *)getFields {
    return fields;
}

- (NSDictionary *)getBinaryFields {
    return binaryFields;
}

- (void)addValue:(id)v forField:(NSString *)f
{
    if ( v == nil && f == nil )
        [fields addObject:[NSArray arrayWithObjects:@"nil",@"nil",nil]];
    else if ( v == nil )
        [fields addObject:[NSArray arrayWithObjects:@"nil",f,nil]];
    else if ( f == nil )
        [fields addObject:[NSArray arrayWithObjects:v,@"nil",nil]];
    else {
        [fields addObject:[NSArray arrayWithObjects:v,f,nil]];
    }
}
//- (void)addValue:(NSData *)v forField:(NSString *)f mimeType:(NSString *)mimeType
- (void)addValue:(NSData *)v forField:(NSString *)f mimeType:(NSString *)mimeType
{
    NSArray* value = [[NSArray alloc] initWithObjects:v, mimeType, nil];
    [binaryFields setValue:value forKey:f];
	[value release];
    
}


- (NSString *)getRandomBoundary
{
	NSMutableString *s = [NSMutableString string];
	[s appendString:kPrefix];
	int i;
	FILE *fp = fopen("/dev/urandom", "r");
	assert(fp);
	for(i=0; i<kRandomPartLength; ++i) {
		char c;
		do c = fgetc(fp); while (!isalnum(c));
		[s appendFormat:@"%c", c];
	}
	fclose(fp);
	return s;
}

- (NSURLRequest *)urlRequest
{
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:2.f];
    
//    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.f];
    
	NSString *boundaryString = [self getRandomBoundary];
	NSData *boundary = [[NSString stringWithFormat:@"--%@\r\n", boundaryString] dataUsingEncoding:NSUTF8StringEncoding];
	NSData *boundaryFinal = [[NSString stringWithFormat:@"--%@--\r\n", boundaryString] dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableData *body = [NSMutableData dataWithData:boundary];
    
	NSEnumerator *en = [fields objectEnumerator];
	NSArray *kv;
    
    // process form fields
	id v;
	NSString *k;
	while( (kv = [en nextObject]) ) {
		v = [kv objectAtIndex:0];
		k = [kv objectAtIndex:1];
		if([v isKindOfClass:[NSString class]]) {
            v = [v dataUsingEncoding:NSUTF8StringEncoding];
		} else {
			// other stuff is processed by description
			v = [[v description] dataUsingEncoding:NSUTF8StringEncoding];
		}
        
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\";\r\n\r\n", k] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:v];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        if (kv == [fields lastObject] && [binaryFields count] == 0) {
            [body appendData:boundaryFinal];
        } else {
            [body appendData:boundary];
        }
	}
    
    // process binary data
    NSString* field;
    NSArray* dataPair;
    NSData* data;
    NSString* mimeType;
    int i = 0;
    for (field in binaryFields) {
        dataPair = [binaryFields valueForKey:field];
        data = [dataPair objectAtIndex:0];
        mimeType = [dataPair objectAtIndex:1];
        
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"temp\"\r\n", field] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:data];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        if (++i == [binaryFields count]) {
            [body appendData:boundaryFinal];
        } else {
            [body appendData:boundary];
        }
    }
    
	[urlRequest setHTTPMethod:@"POST"];
	NSString *ct = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundaryString];
	[urlRequest setValue:ct forHTTPHeaderField: @"Content-Type"];
	[urlRequest setHTTPBody:body];
    
	return urlRequest;
}

- (NSString*) description
{
    return [NSString stringWithFormat: @"GeneralMultipartRequest with URL: %@, fields: %@, and binary fields: %@", url, fields, binaryFields];
}

@end
