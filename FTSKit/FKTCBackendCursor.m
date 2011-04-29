//
//  FKTCBackendCursor.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKTCBackendCursor.h"
#import "FKDataBuffer.h"

@implementation FKTCBackendCursor

- (id)initWithFile:(TCHDB *)f {
    [super init];
    file = f;
    bool successful = tchdbiterinit(file);
    if (!successful) {
        int ecode = tchdbecode(file);
        NSLog(@"Bad tchdbiterinit in initWithFile: %s", tchdberrmsg(ecode));
    }
    
    return self;
}

- (UInt32)nextBuffer:(FKDataBuffer *)buff {
    UInt32 result;
    UInt32 *buffer;
    int size;
    buffer = (UInt32 *)tchdbiternext(file, &size);
    
    if (!buffer) {
        return 0;
    }
    
    result = CFSwapInt32LittleToHost(*buffer);
    
    // Avoid fetching data if possible.
    if (nil != buff) {
        int bufferSize;
        void *data = tchdbget(file, buffer, sizeof(UInt32), &bufferSize);
        
        [buff setData:data length:bufferSize];
    }
    
    free(buffer);
    
    return result;
}

@end
