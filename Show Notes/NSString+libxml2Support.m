//
//  NSString+libxml2Support.m
//
//  Created by Todd Ditchendorf
//

#import "NSString+libxml2Support.h"
#import <libxml/xmlstring.h>

@implementation NSString (libxml2Support)

+ (id)stringWithXmlChar:(const xmlChar *)xc {
    if (NULL == xc) {
        return nil;
    }
	return [[self class] stringWithUTF8String:(char *)xc];
}

- (const xmlChar *)xmlChar {
	return (const unsigned char *)[self UTF8String];
}

@end

