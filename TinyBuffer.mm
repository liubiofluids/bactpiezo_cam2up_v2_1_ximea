//
//  TinyBuffer.m
//  bacttrack
//
//  Created by Bin Liu on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TinyBuffer.h"

@implementation TinyBuffer

-(id) initWithSize: (size_t) num_object ByteOfOjbect: (size_t) siz_object {
    if (self=[super init]){
        size_t buffer_size=(num_object+1)*siz_object;
        objectSize=siz_object;
        NSLog(@"buffersize: %lu", buffer_size);
        byteSize=buffer_size;
        phead = malloc(buffer_size);
        pexchange=malloc(buffer_size);
        occpSize=siz_object;
        counter=0;
    }
    return self;
}

-(void) dealloc
{
    if (phead) {
        free(phead);
    }
    if (pexchange){
        free(pexchange);
    }
}

-(void) push: (void*) pblock SizeOfBlock : (size_t) blockSize{

    if (occpSize+blockSize<byteSize) {
        counter++;
        
    }
}
@end
