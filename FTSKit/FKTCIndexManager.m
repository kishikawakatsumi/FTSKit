//
//  FKTCIndexManager.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKTCIndexManager.h"
#import "FKStoredObject.h"

#pragma mark Private Classes

@interface FKTextIndex : NSObject {
    TCIDB *file;
}

@property (nonatomic, assign) TCIDB *file;

@end;

@implementation FKTextIndex

@synthesize file;

- (void)dealloc {
    tcidbclose(file);
    tcidbdel(file);
    [super dealloc];
}

@end

@interface FKClassKey : NSObject {
    Class keyClass;
    NSString *key;
}

@property (nonatomic, assign) Class keyClass;
@property (nonatomic, copy) NSString *key;

@end

@implementation FKClassKey

@synthesize keyClass, key;

- (void)dealloc {
    [key release];
    [super dealloc];
}

- (NSUInteger)hash {
    return (NSUInteger)keyClass + [key hash];
}

- (BOOL)isEqual:(id)object {
    FKClassKey *other = (FKClassKey *)object;
    return ([other class] == [self class]) && [[other key] isEqual:[self key]];
}

- (id)copyWithZone:(NSZone *)zone {
    [self retain];
    return self;
}

@end

@implementation FKTCIndexManager

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
    
    textIndexes = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)close {
    [textIndexes removeAllObjects];
}

- (void)dealloc  {
    [self close];
    [textIndexes release];
    [path release];
    [super dealloc];
}

- (NSString *)path {
    return path;
}

- (TCIDB *)textIndexForClass:(Class)c key:(NSString *)k {
    FKClassKey *ck = [[FKClassKey alloc] init];
    [ck setKeyClass:c];
    [ck setKey:k];
    
    FKTextIndex *ti = [textIndexes objectForKey:ck];
    
    if (!ti) {
        NSString *filename = [[NSString alloc] initWithFormat:@"%@-%@.tindx", NSStringFromClass(c), k];
        NSString *tiPath = [path stringByAppendingPathComponent:filename];
        [filename release];
        
        int mode = HDBOREADER | HDBOWRITER | HDBONOLCK | HDBOCREAT;
        
        TCIDB *newDB = tcidbnew();
        
        if (!tcidbopen(newDB, [tiPath cStringUsingEncoding:NSUTF8StringEncoding], mode)) {
            int ecode = tcidbecode(newDB);
            NSLog(@"Error opening %@: %s\n", tiPath, tcidberrmsg(ecode));
            @throw [NSException exceptionWithName:@"DB Error" reason:@"Unable to open file" userInfo:nil];
            return NULL;
        }
        ti = [[FKTextIndex alloc] init];
        [ti setFile:newDB];
        [textIndexes setObject:ti forKey:ck];
        [ti autorelease];
    }
    [ck release];
    return [ti file];
}

- (UInt32)countOfRowsInClass:(Class)c matchingText:(NSString *)toMatch forKey:(NSString *)key list:(UInt32 **)listPtr {
    TCIDB *ti = [self textIndexForClass:c key:key];
    const char * cMatch = [toMatch cStringUsingEncoding:NSUTF8StringEncoding];
    int recordCount;
    uint64_t *searchResults = tcidbsearch2(ti, cMatch, &recordCount);
    
    if (listPtr && recordCount > 0) {
        UInt32 *outputBuffer = (UInt32 *)malloc(recordCount * sizeof(UInt32));
        
        for (int i = 0; i < recordCount; i++) {
            outputBuffer[i] = (UInt32)searchResults[i];
        }
        *listPtr = outputBuffer;
    }
    free(searchResults);
    
    return (UInt32)recordCount;
}

- (uint64_t *)searchResultsInClass:(Class)c matchingText:(NSString *)toMatch forKey:(NSString *)key recordCount:(UInt32 *)recordCount {
    TCIDB *ti = [self textIndexForClass:c key:key];
    const char * cMatch = [toMatch cStringUsingEncoding:NSUTF8StringEncoding];
    uint64_t *searchResults = tcidbsearch2(ti, cMatch, (int *)recordCount);
    
    return searchResults;
}

- (void)insertObjectInIndexes:(FKStoredObject *)obj {
    Class c = [obj class];
    UInt32 rowID = [obj rowID];
    NSSet *indexKeys = [c textIndexedAttributes];
    for (NSString *key in indexKeys) {
        TCIDB *ti = [self textIndexForClass:c key:key];
        NSString *value = [obj valueForKey:key];
        const char * cValue = [value cStringUsingEncoding:NSUTF8StringEncoding];
        BOOL success = tcidbput(ti, rowID, cValue);
        if (!success) {
            NSLog(@"Insert of %@ into index (%@, %@) failed", value, NSStringFromClass(c), key);
        } 
    }
}

- (void)deleteObjectFromIndexes:(FKStoredObject *)obj {
    Class c = [obj class];
    UInt32 rowID = [obj rowID];
    NSSet *indexKeys = [c textIndexedAttributes];
    for (NSString *key in indexKeys) {
        TCIDB *ti = [self textIndexForClass:c key:key];
        BOOL success = tcidbout(ti, rowID);
        if (!success) {
            NSLog(@"Delete from index (%@, %@) failed", NSStringFromClass(c), key);
        }
    }
    
}

- (void)updateObjectInIndexes:(FKStoredObject *)obj {
    Class c = [obj class];
    UInt32 rowID = [obj rowID];
    
    NSSet *keys = [[obj class] textIndexedAttributes];
    
    for (NSString *key in keys) {
        TCIDB *ti = [self textIndexForClass:c key:key];
        BOOL success = tcidbout(ti, rowID);
        if (!success) {
            NSLog(@"Delete from index (%@, %@) failed", NSStringFromClass(c), key);
        }
        
        NSString *value = [obj valueForKey:key];
        const char * cValue = [value cStringUsingEncoding:NSUTF8StringEncoding];
        success = tcidbput(ti, rowID, cValue);
        if (!success) {
            NSLog(@"Insert of %@ into index (%@, %@) failed", value, NSStringFromClass(c), key);
        }        
    }
}

@end
