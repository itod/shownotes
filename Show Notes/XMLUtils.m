/*
 *  XMLUtils.m
 *  FantasyFootball
 *
 *  Created by Todd Ditchendorf on 6/1/09.
 *  Copyright 2009 Todd Ditchendorf. All rights reserved.
 *
 */

#import "XMLUtils.h"
#import "NSString+libxml2Support.h"
#import <libxml/xpathInternals.h>

NSString *XMLGetXMLStringFromDocument(xmlDocPtr doc) {
    if (!doc) return nil;
    
    xmlChar *chars = NULL;
    int len = 0;
    xmlDocDumpMemoryEnc(doc, &chars, &len, "utf-8");
    NSString *XMLString = [[[NSString alloc] initWithBytesNoCopy:chars
                                                          length:len
                                                        encoding:NSUTF8StringEncoding
                                                    freeWhenDone:NO] autorelease];
    xmlFree((void *)chars);
    return XMLString;
}


NSString *XMLGetXMLStringFromElement(xmlNodePtr el) {
    if (!el || XML_ELEMENT_NODE != el->type || !el->doc) return nil;
    
    xmlBufferPtr buf = xmlBufferCreate();
    xmlNodeDump(buf, el->doc, el, 4, 1);
    const xmlChar *chars = xmlBufferContent(buf);
    
    NSString *XMLString = [NSString stringWithXmlChar:chars];
    
	//xmlFree((void *)chars); don't free this. it's freed in xmlBufferFree() !!1!!!11!
    xmlBufferFree(buf);
    return XMLString;
}

// <title>foo &amp; bar <![CDATA[&]]> baz</title>
NSString *XMLGetStringContent(xmlNodePtr n) {
    if (!n) return nil;
    
    NSMutableString *mstr = nil;
    if (XML_TEXT_NODE == n->type || XML_CDATA_SECTION_NODE == n->type || XML_ENTITY_REF_NODE == n->type) {
        mstr = [NSMutableString stringWithXmlChar:n->content];
    } else if (XML_ELEMENT_NODE == n->type) {
        mstr = [NSMutableString string];
        
        xmlNodePtr child = NULL;
        for (child = n->children; child; child = child->next) {
            NSString *s = XMLGetStringContent(child);
            if (s) [mstr appendString:s];
        }
    }
    
    if (mstr) {
        [mstr replaceOccurrencesOfString:@"&amp;" withString:@"&" options:0 range:NSMakeRange(0, [mstr length])];
    }
    
    return mstr;
}


NSNumber *XMLGetNumberContent(xmlNodePtr n) {
    NSString *s = XMLGetStringContent(n);
    return [NSNumber numberWithFloat:[s floatValue]];
}


NSInteger XMLGetChildNodeCount(xmlNodePtr n) {
    NSInteger i = 0;
    xmlNodePtr child = NULL;
    for (child = n->children; child; child = child->next) {
        i++;
    }
    return i;
}

NSInteger XMLGetChildElementCount(xmlNodePtr n, const char *tagName) {
    NSInteger i = 0;
    xmlNodePtr child = NULL;
    for (child = n->children; child; child = child->next) {
        if (XML_ELEMENT_NODE == child->type && XMLTagNameEquals(child, tagName)) {
            i++;
        }
    }
    return i;
}

NSString *XMLGetAttribute(xmlNodePtr el, const char *attrName) {
    NSString *result = nil;
    xmlChar *str = xmlGetProp(el, (const xmlChar *)attrName);
    if (NULL != str) {
        result = [NSString stringWithXmlChar:str];
        xmlFree(str);
    }
    return result;
}

xmlNodePtr XMLGetFirstChildOfTagName(xmlNodePtr parentEl, const char *tagName) {
    if (!parentEl) return NULL;
    
    xmlNodePtr result = NULL;
    xmlNodePtr currNode = NULL;
    
    for (currNode = parentEl->children; currNode; currNode = currNode->next) {
        if (XML_ELEMENT_NODE == currNode->type) {
            if (XMLTagNameEquals(currNode, tagName)) {
                return currNode;
            }
        }
    }
    
    return result;
}

BOOL XMLTagNameEquals(xmlNodePtr el, const char *tagName) {
    return (0 == strcmp((const char *)el->name, tagName));
}


static NSError *XPathErrorForMessage(NSString *msg) {
    NSLog(@"%@", msg);
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:msg forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"XPath" code:47 userInfo:userInfo];
}

 
BOOL XMLRegisterXPathNamespace(xmlXPathContextPtr xpathCtx, const xmlChar *prefix, const xmlChar *URI, NSError **outErr) {
    if (xmlXPathRegisterNs(xpathCtx, prefix, URI) != 0) {
        NSString *msg = [NSString stringWithFormat:@"Error: unable to register NS with prefix=\"%s\" and href=\"%s\"", prefix, URI];
        NSLog(@"%@", msg);
        if (outErr) {
            *outErr = XPathErrorForMessage(msg);
        }
        return NO;
    } else {
        return YES;
    }
    
}


xmlXPathObjectPtr XMLExecuteXPath(xmlDocPtr doc, const char *xpathExpr, NSError **outErr) {
    /* Create xpath evaluation context */
    xmlXPathContextPtr xpathCtx = xmlXPathNewContext(doc);
    if (NULL == xpathCtx) {
        if (outErr) {
            *outErr = XPathErrorForMessage(@"Error: unable to create new XPath context");
        }
        return NULL;
    }
    
    const xmlChar *prefix = (const xmlChar *)"";
    const xmlChar *URI = (const xmlChar *)"http://api.fantasysports.yahoo.com/fantasy/v2/base.rng";
    if (!XMLRegisterXPathNamespace(xpathCtx, prefix, URI, outErr)) {
        return NULL;
    }
    
    /* Evaluate xpath expression */
    xmlXPathObjectPtr xpathObj = xmlXPathEvalExpression((const xmlChar *)xpathExpr, xpathCtx);
    if (NULL == xpathObj) {
        xmlXPathFreeContext(xpathCtx); 
        if (outErr) {
            *outErr = XPathErrorForMessage([NSString stringWithFormat:@"Error: unable to evaluate xpath expression \"%s\"", xpathExpr]);
        }
        return NULL;
    }
    
    
    /* Cleanup */
    //xmlXPathFreeObject(xpathObj);
    xmlXPathFreeContext(xpathCtx);
    
    return xpathObj;
}
