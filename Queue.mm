/*
 *  Queue.mm
 *  bacttrack
 *
 *  Created by Bin Liu on 9/28/11.
 *  Copyright 2011 New York University. All rights reserved.
 *
 */

#include "Queue.h"

@implementation Queue

- (id)init
{
	if (self=[super init])
	{
        NSLog(@"initobjects\n");
		objects=[[NSMutableArray alloc] init];
 //       [objects addObject: [[NSObject alloc] init]];
	}
	return self;
}
- (void)push:(id)object
{
//    NSLog(@"objects: %d, %d\n", objects, object);
	[objects addObject:object];
//    NSLog(@"objects: %d, %d\n", objects, object);
}
- (id)pop
{
	id object=nil;
	
	if ([objects count])
	{
		object=[objects objectAtIndex:0];
	//	NSLog(@"queue: %d, %d", [objects count], object);
		[objects removeObjectAtIndex:0];
	}
	return object;
}

- (void)dealloc
{
	[objects release];
	[super dealloc];
}

- (uint) size
{
	return [objects count];
}


@end