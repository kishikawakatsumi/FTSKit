//
//  FKTCBackend.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKTCBackend.h"
#import "FKTCBackendCursor.h"
#import "FKDataBuffer.h"

const char *FKToCString(NSString *str, int *lenPtr) {
    const char *cString = [str cStringUsingEncoding:NSUTF8StringEncoding];
    if (lenPtr) {
        *lenPtr = strlen(cString);
    }
    return cString;
}

@implementation FKTCBackend

- (id)initWithPath:(NSString *)p error:(NSError **)err {
    [super init];
    path = [p copy];
    
    BOOL isDir;
    BOOL exists;
    exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    
    if (exists) {
        if (!isDir) {
            if (err) {
                NSMutableDictionary *ui = [NSMutableDictionary dictionary];
                [ui setObject:[NSString stringWithFormat:@"%@ is a file", path] forKey:NSLocalizedDescriptionKey];
                *err = [NSError errorWithDomain:@"FTSKit" code:4 userInfo:ui];
            }
            [self dealloc];
            return nil;
        }
    } else {
        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:err];
        if (!success) {
            [self dealloc];
            return nil;
        }
    }
    
    dbTable = new hash_map<Class, TCHDB *, hash<Class>, equal_to<Class> >(389);
    
    return self;
}

- (void)dealloc {
    [self close];
    [path release];
    delete dbTable;
    [super dealloc];
}

#pragma mark Transaction support

// We don't really do transactions in TC (we could, though)
- (BOOL)beginTransaction {
    return YES;
}

- (BOOL)commitTransaction {
    return YES;
}

- (BOOL)abortTransaction {
    return NO;
}

- (BOOL)hasOpenTransaction {
    return NO;
}

#pragma mark Writing changes

- (void)setFile:(TCHDB *)f forClass:(Class)c {
    (*dbTable)[c] = f;
}

- (TCHDB *)fileForClass:(Class)c; {
    TCHDB *result = (*dbTable)[c];
    if (!result) {
        NSString *classPath = [path stringByAppendingPathComponent:NSStringFromClass(c)];
        
        int mode = HDBOREADER | HDBOWRITER | HDBONOLCK| HDBOCREAT;
        
        result = tchdbnew();
        
        if (!tchdbopen(result, [classPath cStringUsingEncoding:NSUTF8StringEncoding], mode)) {
            int ecode = tchdbecode(result);
            NSLog(@"Error opening %@: %s\n", classPath, tchdberrmsg(ecode));
            @throw [NSException exceptionWithName:@"DB Error" 
                                           reason:@"Unable to open file"
                                         userInfo:nil];
            return NULL;
        }
        [self setFile:result forClass:c];
    }
    return result;
}

- (TCHDB *)namedBufferDB {
    if (!namedBufferDB) {
        
        NSString *classPath = [path stringByAppendingPathComponent:@"NamedBuffers"];
        
        int mode = HDBOREADER | HDBOWRITER | HDBONOLCK| HDBOCREAT;
        
        namedBufferDB = tchdbnew();
        
        if (!tchdbopen(namedBufferDB, [classPath cStringUsingEncoding:NSUTF8StringEncoding], mode)) {
            int ecode = tchdbecode(namedBufferDB);
            NSLog(@"Error opening %@: %s\n", classPath, tchdberrmsg(ecode));
            @throw [NSException exceptionWithName:@"DB Error" 
                                           reason:@"Unable to open file"
                                         userInfo:nil];
            return NULL;
        }
    }
    return namedBufferDB;
}

- (void)insertData:(FKDataBuffer *)d forClass:(Class)c rowID:(UInt32)n {    
    TCHDB *db = [self fileForClass:c];
    UInt32 key = CFSwapInt32HostToLittle(n);
    bool successful = tchdbput(db, &key, sizeof(UInt32), [d buffer], [d length]);
    if (!successful) {
        int ecode = tchdbecode(db);
        NSString *message = [NSString stringWithFormat:@"tchdbput in insertData: %s", tchdberrmsg(ecode)];
        
        NSException *e = [NSException exceptionWithName:@"BadInsert"
                                                 reason:message 
                                               userInfo:nil];
        @throw e;
    }
}

- (void)deleteDataForClass:(Class)c rowID:(UInt32)n {
    TCHDB *db = [self fileForClass:c];
    UInt32 key = CFSwapInt32HostToLittle(n);
    
    bool successful = tchdbout(db, &key, sizeof(UInt32));
    if (!successful) {
        NSLog(@"warning: tried to delete something that wasn't there");
    }
}

- (void)updateData:(FKDataBuffer *)d 
          forClass:(Class)c 
             rowID:(UInt32)n {
    TCHDB *db = [self fileForClass:c];
    UInt32 key = CFSwapInt32HostToLittle(n);    
    
    bool successful = tchdbput(db, &key, sizeof(UInt32), [d buffer], [d length]);
    if (!successful) {
        int ecode = tchdbecode(db);
        NSString *message = [NSString stringWithFormat:@"tchdbput in updateData: %s", tchdberrmsg(ecode)];
        
        NSException *e = [NSException exceptionWithName:@"BadUpdate"
                                                 reason:message 
                                               userInfo:nil];
        @throw e;
    }
}

#pragma mark Named buffers

- (void)insertDataBuffer:(FKDataBuffer *)d forName:(NSString *)key {
    NSAssert (key != nil, @"key must not be nil");
    int bytes;
    const char *cString = FKToCString(key, &bytes);
    
    TCHDB *db = [self namedBufferDB];
    
    bool successful = tchdbput(db, cString, bytes, [d buffer], [d length]);
    if (!successful) {
        int ecode = tchdbecode(db);
        NSString *message = [NSString stringWithFormat:@"tchdbput in insertData:forKey: %s", tchdberrmsg(ecode)];
        
        NSException *e = [NSException exceptionWithName:@"BadInsert"
                                                 reason:message 
                                               userInfo:nil];
        @throw e;
    }
}

- (void)deleteDataBufferForName:(NSString *)key {
    NSAssert (key != nil, @"key must not be nil");
    int bytes;
    const char *cString = FKToCString(key, &bytes);
    
    TCHDB *db = [self namedBufferDB];
    
    bool successful = tchdbout(db, cString, bytes);
    if (!successful) {
        int ecode = tchdbecode(db);
        NSString *message = [NSString stringWithFormat:@"tchdbput in deleteDataForKey: %s", tchdberrmsg(ecode)];
        
        NSException *e = [NSException exceptionWithName:@"BadDelete"
                                                 reason:message 
                                               userInfo:nil];
        @throw e;
    }
}

- (void)updateDataBuffer:(FKDataBuffer *)d forName:(NSString *)key {
    [self insertDataBuffer:d forName:key];
}

- (FKDataBuffer *)dataBufferForName:(NSString *)key {
    NSAssert (key != nil, @"key must not be nil");
    int bytes;
    const char *cString = FKToCString(key, &bytes);
    
    TCHDB *db = [self namedBufferDB];
    
    int bufferSize;
    void *data = tchdbget(db, cString, bytes, &bufferSize);
    
    if (!data) {
        return nil;
    }
    
    FKDataBuffer *b = [[FKDataBuffer alloc] initWithData:data length:bufferSize];
    return [b autorelease];
}

- (NSSet *)allNames {
    TCHDB *db = [self namedBufferDB];
    
    bool successful = tchdbiterinit(db);
    if (!successful) {
        int ecode = tchdbecode(db);
        NSLog(@"Bad tchdbiterinit in initWithFile: %s", tchdberrmsg(ecode));
    }
    
    NSMutableSet *result = [NSMutableSet set];
    char *buffer;
    int size;
    while ((buffer = (char *)tchdbiternext(db, &size))) {
        NSString *newKey = [[NSString alloc] initWithBytesNoCopy:buffer
                                                          length:size
                                                        encoding:NSUTF8StringEncoding
                                                    freeWhenDone:YES];
        [result addObject:newKey];
        [newKey release];
    }
    
    return result;
}

#pragma mark Fetching

- (FKDataBuffer *)dataForClass:(Class)c rowID:(UInt32)n {
    TCHDB * db = [self fileForClass:c];
    UInt32 key = CFSwapInt32HostToLittle(n);
    
    int bufferSize;
    void *data = tchdbget(db, &key, sizeof(UInt32), &bufferSize);
    
    if (!data) {
        return nil;
    }
    
    FKDataBuffer *b = [[FKDataBuffer alloc] initWithData:data length:bufferSize];
    return [b autorelease];
}

- (FKBackendCursor *)cursorForClass:(Class)c {
    TCHDB *db = [self fileForClass:c];
    if (!db) {
        return nil;
    }
    
    FKTCBackendCursor *cu = [[FKTCBackendCursor alloc] initWithFile:db];
    return [cu autorelease];
}

- (void)close {
    hash_map<Class, TCHDB *, hash<Class>, equal_to<Class> >::iterator iter = dbTable->begin();
    while (iter != dbTable->end()) {
        TCFileHashedPair currentPair = *iter;
        TCHDB * dbp = currentPair.second;
        tchdbclose(dbp);
        tchdbdel(dbp);
        iter++;
    }
    dbTable->clear();
    
    if (namedBufferDB) {
        tchdbclose(namedBufferDB);
        tchdbdel(namedBufferDB);
        namedBufferDB = NULL;
    }
}

- (NSString *)path {
    return path;
}

@end
