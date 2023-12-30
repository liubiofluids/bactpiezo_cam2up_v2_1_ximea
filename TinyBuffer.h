//
//  TinyBuffer.h
//  bacttrack
//
//  Created by Bin Liu on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TinyBuffer : NSObject{
    void* phead;
    void* pexchange;
    size_t byteSize;
    size_t occpSize;
    size_t objectSize;
    size_t counter;
}

-(id) initWithSize : (size_t) buffer_size ByteOfOjbect: (size_t) siz_object;

-(void) push: (void*) pblock SizeOfBlock : (size_t) blockSize;
-(void) dealloc;
@end
