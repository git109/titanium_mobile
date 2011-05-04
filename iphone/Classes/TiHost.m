/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiHost.h"
#import "TiProxy.h"
#import "TiModule.h"
#import "SBJSON.h"

#ifdef DEBUG
#define DEBUG_EVENTS 0
#endif

#if TARGET_IPHONE_SIMULATOR
extern NSString * const TI_APPLICATION_RESOURCE_DIR;
#endif

extern NSString * const TI_APPLICATION_ID;


@implementation TiHost
@synthesize debugMode;

+(NSURL*)resolveFilePathForAppUrl:(NSURL*)appUrl
{
	if (![[appUrl scheme] isEqualToString:@"app"])
	{//Whoops! We don't need to translate!
		return appUrl;
	}

	NSString *resourcePath = [[NSBundle mainBundle] bundlePath];
#if TARGET_IPHONE_SIMULATOR
	if (TI_APPLICATION_RESOURCE_DIR!=nil && ![TI_APPLICATION_RESOURCE_DIR isEqualToString:@""])
	{
		// if the .local file exists and we're in the simulator, then force load from resources bundle
		NSString * localFilePath = [resourcePath stringByAppendingPathComponent:@".local"];
		if (![[NSFileManager defaultManager] fileExistsAtPath:localFilePath])
		{
			// we use our app resource directory
			resourcePath = TI_APPLICATION_RESOURCE_DIR;
		}
	}
#endif
	
	NSString * result = [resourcePath stringByAppendingPathComponent:[appUrl path]];
	return [NSURL fileURLWithPath:result];
}

+(NSURL*)resourceBasedURL:(NSString*)fn baseURL:(NSString**)base
{
	NSString *path = [[NSBundle mainBundle] bundlePath];
#if TARGET_IPHONE_SIMULATOR
	if (TI_APPLICATION_RESOURCE_DIR!=nil && [TI_APPLICATION_RESOURCE_DIR isEqualToString:@""]==NO)
	{
		// if the .local file exists and we're in the simulator, then force load from resources bundle
		if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/.local",[[NSBundle mainBundle] resourcePath]]])
		{
			// we use our app resource directory
			path = TI_APPLICATION_RESOURCE_DIR;
		}
	}
#endif
	NSString *fullpath = [NSString stringWithFormat:@"%@/%@",path,fn];
	if (base!=NULL)
	{
		*base = [fullpath stringByDeletingLastPathComponent];
	}
	return [NSURL fileURLWithPath:fullpath];
}

-(id)init
{
	if (self = [super init])
	{
		modules = [[NSMutableDictionary alloc] init];
		contexts = [[NSMutableDictionary alloc] init];
		 
		NSString *fn = @"app.js";
		const char *start = getenv("TI_STARTPAGE");
		if (start!=NULL)
		{
			fn = [NSString stringWithCString:start encoding:NSUTF8StringEncoding];
		}
		NSString *base;
		NSURL *url = [TiHost resourceBasedURL:fn baseURL:&base];
		startURL = [url retain];
		baseURL = [[NSURL fileURLWithPath:base] retain];
		stylesheet = [[TiStylesheet alloc] init];
        debugMode = NO;
	}
	return self;
}

-(NSString*)appID
{
	return TI_APPLICATION_ID;
}

-(NSURL*)baseURL
{
	return baseURL;
}

-(NSURL*)startURL
{
	return startURL;
}

-(TiStylesheet*)stylesheet
{
	return stylesheet;
}

-(void)dealloc
{
	RELEASE_TO_NIL(modules);
	RELEASE_TO_NIL(contexts);
	RELEASE_TO_NIL(baseURL);
	RELEASE_TO_NIL(startURL);
	RELEASE_TO_NIL(stylesheet);
	[super dealloc];
}

-(id<TiEvaluator>)contextForToken:(NSString*)token
{
	return [contexts objectForKey:token];
}

-(void)registerContext:(id<TiEvaluator>)context forToken:(NSString*)token
{
	[contexts setValue:context forKey:token];
}

-(void)unregisterContext:(id<TiEvaluator>)context forToken:(NSString*)token
{
	[contexts removeObjectForKey:token];
}

-(id) moduleNamed:(NSString*)name context:(id<TiEvaluator>)context
{
	TiModule *m = [modules objectForKey:name];
	if (m == nil || [m destroyed]) // Need to re-allocate any modules which have been destroyed
	{
		Class moduleClass = NSClassFromString([NSString stringWithFormat:@"%@Module",name]);
		if (moduleClass!=nil)
		{
			m = [[moduleClass alloc] _initWithPageContext:context];
			[m setHost:self];
			[modules setObject:m forKey:name];
			[m release];
		}
	}
	
	return m;
}

-(void)evaluateJS:(NSString*)js context:(id<TiEvaluator>)evaluator
{
	[evaluator evalJSWithoutResult:js];
}	

-(void)fireEvent:(id)listener withObject:(id)obj remove:(BOOL)yn context:(id<TiEvaluator>)evaluator thisObject:(TiProxy*)thisObject_
{
#if DEBUG_EVENTS==1
	NSLog(@"fireEvent: %@, object: %@",listener,obj);
#endif	
	[evaluator fireEvent:listener withObject:obj remove:yn thisObject:thisObject_];
}

-(void)removeListener:(id)listener context:(id<TiEvaluator>)context
{
}

@end
