//
//  NSString+libxml2Support.h
//
//  Created by Todd Ditchendorf
//

#import <Foundation/Foundation.h>
#import <libxml/xmlstring.h>

@interface NSString (libxml2Support)
+ (id)stringWithXmlChar:(const xmlChar *)xc;
- (const xmlChar *)xmlChar;
@end

