/*
 *  XMLUtils.h
 *  FantasyFootball
 *
 *  Created by Todd Ditchendorf on 6/1/09.
 *  Copyright 2009 Todd Ditchendorf. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#import <libxml/xmlmemory.h>
#import <libxml/xpath.h>

NSString *XMLGetXMLStringFromDocument(xmlDocPtr doc);
NSString *XMLGetXMLStringFromElement(xmlNodePtr el);
NSString *XMLGetStringContent(xmlNodePtr n);
NSNumber *XMLGetNumberContent(xmlNodePtr n);
NSInteger XMLGetChildNodeCount(xmlNodePtr n);
NSInteger XMLGetChildElementCount(xmlNodePtr n, const char *tagName);
NSString *XMLGetAttribute(xmlNodePtr el, const char *attrName);
xmlNodePtr XMLGetFirstChildOfTagName(xmlNodePtr parentEl, const char *tagName);
BOOL XMLTagNameEquals(xmlNodePtr el, const char *tagName);


// to use the result as a node-set, do:
//          xmlXPathObjectPtr xpathObj = XMLExecuteXPath(doc, "foo/bar[baz]", &err);
//          xmlNodeSet results = xpathObj->nodesetval;
//          // do stuff with results
//          xmlXPathFreeObject(xpathObj); // *client code ****MUST**** free this object!
xmlXPathObjectPtr XMLExecuteXPath(xmlDocPtr doc, const char *xpathExpr, NSError **outErr);

#define	SET_SAFE_KEY_VALUE(d,v,k)   if (v) {[d setObject:v forKey:k];}
