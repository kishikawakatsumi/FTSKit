//
//  FKStore.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKStore.h"
#import "FKStoreBackend.h"
#import "FKStoredObject.h"
#import "FKBackendCursor.h"
#import "FKDataBuffer.h"
#import "FKResultSet.h"
#import "FKClassDictionary.h"
#import "FKClassMetaData.h"
#import "FKUniquingTable.h"
#import "FKIndexManager.h"
#import "FKDataBuffer+Encryption.h"

#ifndef PAGE_SIZE
#define PAGE_SIZE (4096)
#endif

@interface FKStoredObject (FKStoreFriend)

- (void)setHasContent:(BOOL)yn;
- (id)initWithStore:(FKStore *)s rowID:(UInt32)n buffer:(FKDataBuffer *)buffer;

@end

@implementation FKStore

@synthesize backend;
@synthesize indexManager;
@synthesize undoManager;
@synthesize delegate;
@synthesize usesPerInstanceVersioning;
@synthesize encryptionKey;

- (id)init {
    [super init];
    uniquingTable = [[FKUniquingTable alloc] init];
    toBeInserted = [[NSMutableSet alloc] init];
    toBeDeleted = [[NSMutableSet alloc] init];
    toBeUpdated = [[NSMutableSet alloc] init];
    classMetaData = [[FKClassDictionary alloc] init];
    usesPerInstanceVersioning = YES; // Adds an 8-bit number to every record, but enables versioning...
    return self;
}

- (void)dealloc {
    [uniquingTable release];
    [backend release];
    [undoManager release];
    [indexManager close];
    [indexManager release];
    [toBeInserted release];
    [toBeDeleted release];
    [toBeUpdated release];
    [classMetaData release];
    [encryptionKey release];
    [super dealloc];
}

- (void)makeEveryStoredObjectPerformSelector:(SEL)s {
    [uniquingTable makeAllObjectsPerformSelector:s];
}

- (void)dissolveAllRelationships {
    [self makeEveryStoredObjectPerformSelector:@selector(dissolveAllRelationships)];
}

- (void)addClass:(Class)c {    
    // Put it in the first empty slot
    int classCount = 0;
    while (classes[classCount] != NULL) {
        classCount++;
        if (classCount == 255) {
            [NSException raise:@"BNRStore classes array is full"
                        format:@"Class %@ was not added to %@", NSStringFromClass(c), self];
        }
    }
    classes[classCount] = c;
}

- (BOOL)decryptBuffer:(FKDataBuffer *)buffer ofClass:(Class)c rowID:(UInt32)rowID {
    if (!buffer) {
        return YES;
    }
    
    FKClassMetaData *metaData = [self metaDataForClass:c];
    
    UInt32 salt[2];
    memcpy(salt, [metaData encryptionKeySalt], 8);
    salt[1] = salt[1] ^ rowID;
    
    return [buffer decryptWithKey:encryptionKey salt:salt];
}

- (void)encryptBuffer:(FKDataBuffer *)buffer ofClass:(Class)c rowID:(UInt32)rowID {
    UInt32 salt[2];
    memcpy(salt, [[self metaDataForClass:c] encryptionKeySalt], 8);
    salt[1] = salt[1] ^ rowID;
    [buffer encryptWithKey:encryptionKey salt:salt]; // does not encrypt if encryptionKey is empty.
}

#pragma mark Fetching

- (FKStoredObject *)objectForClass:(Class)c rowID:(UInt32)n fetchContent:(BOOL)mustFetch {
    // Try to find it in the uniquing table
    FKStoredObject *obj = [uniquingTable objectForClass:c rowID:n];
    if (obj) {
        if (mustFetch && ![obj hasContent]) {
            FKDataBuffer *const d = [backend dataForClass:c rowID:n];
            [self decryptBuffer:d ofClass:c rowID:n];
            if (usesPerInstanceVersioning) {
                [d consumeVersion];
            }
            [obj readContentFromBuffer:d];
            [obj setHasContent:YES];
        }
    } else {
        FKDataBuffer *const d = mustFetch? [backend dataForClass:c rowID:n] : nil;
        [self decryptBuffer:d ofClass:c rowID:n];
        if (usesPerInstanceVersioning) {
            [d consumeVersion];
        }
        obj = [[[c alloc] initWithStore:self rowID:n buffer:d] autorelease];
        [uniquingTable setObject:obj forClass:c rowID:n];
    }
    
    return obj;
}

- (NSMutableArray *)allObjectsForClass:(Class)c {
    // Fetch!
    FKBackendCursor *const cursor = [backend cursorForClass:c];
    if (!cursor) {
        NSLog(@"No database for %@", NSStringFromClass(c));
        return nil;
    }
    
    NSMutableArray *const allObjects = [NSMutableArray array];
    FKDataBuffer *const buffer = [[[FKDataBuffer alloc] initWithCapacity:(UINT16_MAX + 1)] autorelease];
    
    UInt32 rowID;
    while ((rowID = [cursor nextBuffer:buffer]) != 0) {
        if (kFKMetadataRowID == rowID) {
            continue;  // skip metadata
        }
        
        // Get the next object.
        FKStoredObject *storedObject = [self objectForClass:c rowID:rowID fetchContent:NO];
        [allObjects addObject:storedObject];
        
        // Possibly read in its stored data.
        const BOOL hasUnsavedData = [toBeUpdated containsObject:storedObject];
        if (!hasUnsavedData) {
            [self decryptBuffer:buffer ofClass:c rowID:rowID];
            if (usesPerInstanceVersioning) {
                [buffer consumeVersion];
            }
            [storedObject readContentFromBuffer:buffer];
            [storedObject setHasContent:YES];
        }
    }
    
    return allObjects;
}

#if NS_BLOCKS_AVAILABLE
- (void)enumerateAllObjectsForClass:(Class)c usingBlock:(FKStoredObjectIterBlock)iterBlock {
    // Fetch!
    FKBackendCursor *const cursor = [backend cursorForClass:c];
    if (!cursor) {
        NSLog(@"No database for %@", NSStringFromClass(c));
        return;
    }
    
    FKDataBuffer *const buffer = [[[FKDataBuffer alloc] initWithCapacity:(UINT16_MAX + 1)] autorelease];
    
    UInt32 rowID;
    while ((rowID = [cursor nextBuffer:buffer]) != 0) {
        if (kFKMetadataRowID == rowID) continue;  // skip metadata
        
        // Prevent our usage from building up while iterating over the objects:
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // Get the next object.
        FKStoredObject *storedObject = [self objectForClass:c rowID:rowID fetchContent:NO];
        
        // Possibly read in its stored data.
        const BOOL hasUnsavedData = [toBeUpdated containsObject:storedObject];
        if (!hasUnsavedData) {
            [self decryptBuffer:buffer ofClass:c rowID:rowID];
            if (usesPerInstanceVersioning) {
                [buffer consumeVersion];
            }
            [storedObject readContentFromBuffer:buffer];
            [storedObject setHasContent:YES];
        }
        
        BOOL stop = NO;
        iterBlock(rowID, storedObject, &stop);
        
        [pool drain];
        
        if (stop) {
            break;
        }
    }
}
#endif

- (NSMutableArray *)objectsForClass:(Class)c matchingText:(NSString *)toMatch forKey:(NSString *)key {
    if (!indexManager) {
        NSLog(@"No fulltext search without an index manager");
        return nil;
    }
    
    UInt32 *indexResult;
    UInt32 rowCount = [indexManager countOfRowsInClass:c matchingText:toMatch forKey:key list:&indexResult];
    
    NSMutableArray *result = [NSMutableArray array];
    for (UInt32 i = 0; i < rowCount; i++) {
        UInt32 rowID = indexResult[i];
        FKStoredObject *obj = [self objectForClass:c rowID:rowID fetchContent:NO];
        [result addObject:obj];
    }
    if (rowCount > 0) {
        free(indexResult);
    }
    
    return result;
}

- (NSMutableArray *)objectsForClass:(Class)c mactchesText:text forKey:(NSString *)key {
    return [self objectsForClass:c matchingText:[NSString stringWithFormat:@"[[%@]]", text] forKey:key];
}

- (NSMutableArray *)objectsForClass:(Class)c containsText:text forKey:(NSString *)key {
    return [self objectsForClass:c matchingText:[NSString stringWithFormat:@"[[*%@*]]", text] forKey:key];
}

- (NSMutableArray *)objectsForClass:(Class)c beginsWithText:text forKey:(NSString *)key {
    return [self objectsForClass:c matchingText:[NSString stringWithFormat:@"[[%@*]]", text] forKey:key];
}

- (NSMutableArray *)objectsForClass:(Class)c endsWithText:text forKey:(NSString *)key {
    return [self objectsForClass:c matchingText:[NSString stringWithFormat:@"[[*%@]]", text] forKey:key];
}

- (FKResultSet *)resultSetForClass:(Class)c matchingText:(NSString *)toMatch forKey:(NSString *)key {
    if (!indexManager) {
        NSLog(@"No fulltext search without an index manager");
        return nil;
    }
    
    UInt32 rowCount;
    uint64_t *searchResults = [indexManager searchResultsInClass:c matchingText:toMatch forKey:key recordCount:&rowCount];
    
    FKResultSet *resultSet;
    if (rowCount > 0) {
        resultSet = [[FKResultSet alloc] initWithStore:self forClass:c rowCount:rowCount rowIDs:searchResults];
    } else {
        resultSet = [[FKResultSet alloc] init];
    }
    
    return resultSet;
}

- (FKResultSet *)resultSetForClass:(Class)c mactchesText:(NSString *)text forKey:(NSString *)key {
    return [self resultSetForClass:c matchingText:[NSString stringWithFormat:@"[[%@]]", text] forKey:key];
}

- (FKResultSet *)resultSetForClass:(Class)c containsText:(NSString *)text forKey:(NSString *)key {
    return [self resultSetForClass:c matchingText:[NSString stringWithFormat:@"[[*%@*]]", text] forKey:key];
}

- (FKResultSet *)resultSetForClass:(Class)c beginsWithText:(NSString *)text forKey:(NSString *)key {
    return [self resultSetForClass:c matchingText:[NSString stringWithFormat:@"[[%@*]]", text] forKey:key];
}

- (FKResultSet *)resultSetForClass:(Class)c endsWithText:(NSString *)text forKey:(NSString *)key {
    return [self resultSetForClass:c matchingText:[NSString stringWithFormat:@"[[*%@]]", text] forKey:key];
}

#pragma mark Insert, update, delete

- (BOOL)hasUnsavedChanges {
    return [toBeDeleted count] || [toBeInserted count] || [toBeUpdated count];
}

- (void)insertObject:(FKStoredObject *)obj {
    [obj setStore:self];
    
    Class c = [obj class];
    UInt32 rowID = [obj rowID];
    
    // Should I really be giving this object
    // a row ID?
    if (rowID == 0) {
        rowID = [self nextRowIDForClass:c];
        [obj setRowID:rowID];
    }
    
    // Put it in the uniquing table
    [uniquingTable setObject:obj forClass:c rowID:rowID];
    
    if (undoManager) {
        [(FKStore *)[undoManager prepareWithInvocationTarget:self] deleteObject:obj];
    }
    
    [self willChangeValueForKey:@"hasUnsavedChanges"];
    [toBeInserted addObject:obj];
    [toBeUpdated removeObject:obj];
    [toBeDeleted removeObject:obj];
    [self didChangeValueForKey:@"hasUnsavedChanges"];
    
    if (delegate) {
        [delegate store:self willInsertObject:obj];
    }
}

// This insert is used when undoing a delete
- (void)insertWithRowID:(unsigned)rowID
                  class:(Class)c
               snapshot:(FKDataBuffer *)snap {
    FKStoredObject *obj = [self objectForClass:c
                                          rowID:rowID
                                   fetchContent:NO];
    if (usesPerInstanceVersioning) {
        [snap consumeVersion];
    }
    [obj readContentFromBuffer:snap];
    [self insertObject:obj];
    [obj release];
}

- (void)deleteObject:(FKStoredObject *)obj {
    // Prevents infinite recursion (see prepareForDelete)
    if ([toBeDeleted containsObject:obj]) {
        return;
    }
    
    [self willChangeValueForKey:@"hasUnsavedChanges"];
    
    if ([toBeInserted containsObject:obj]){
        [toBeInserted removeObject:obj];
    } else {
        [toBeDeleted addObject:obj];
    }
    
    // No need to insert or update deleted objects
    [toBeUpdated removeObject:obj];
    
    [self didChangeValueForKey:@"hasUnsavedChanges"];
    
    // Store away current values
    if (undoManager) {
        FKDataBuffer *snapshot = [[FKDataBuffer alloc] initWithCapacity:PAGE_SIZE];
        if (usesPerInstanceVersioning) {
            [snapshot writeVersionForObject:obj];
        }
        
        [obj writeContentToBuffer:snapshot];
        [snapshot resetCursor];
        
        unsigned rowID = [obj rowID];
        Class c = [obj class];
        [[undoManager prepareWithInvocationTarget:self] insertWithRowID:rowID class:c snapshot:snapshot];
        [snapshot release];
    }
    
    // objects implement their own delete rules - cascade, whatever
    [obj prepareForDelete];
    
    if (delegate) {
        [delegate store:self willDeleteObject:obj];
    }
}

- (void)updateObject:(FKStoredObject *)obj withSnapshot:(FKDataBuffer *)b {
    // Store away current values
    if (undoManager) {
        FKDataBuffer *snapshot = [[FKDataBuffer alloc] initWithCapacity:PAGE_SIZE];
        if (usesPerInstanceVersioning) {
            [snapshot writeVersionForObject:obj];
        }
        
        [obj writeContentToBuffer:snapshot];
        [snapshot resetCursor];
        [[undoManager prepareWithInvocationTarget:self] updateObject:obj withSnapshot:snapshot];
        [snapshot release];
    }
    
    if (usesPerInstanceVersioning) {
        [b consumeVersion];
    }
    
    [obj readContentFromBuffer:b];
    if (delegate) {
        [delegate store:self didChangeObject:obj];
    }
    
    [toBeUpdated addObject:obj];
    if (delegate) {
        [delegate store:self willUpdateObject:obj];
    }
}

- (void)willUpdateObject:(FKStoredObject *)obj {
    if (undoManager) {
        FKDataBuffer *snapshot = [[FKDataBuffer alloc]
                                   initWithCapacity:PAGE_SIZE];
        if (usesPerInstanceVersioning) {
            [snapshot writeVersionForObject:obj];
        }
        
        [obj writeContentToBuffer:snapshot];
        [snapshot resetCursor];
        
        [[undoManager prepareWithInvocationTarget:self] updateObject:obj 
                                                        withSnapshot:snapshot];
        [snapshot release];
    }
    
    if (delegate) {
        [delegate store:self willUpdateObject:obj];
    }
    
    // No need to insert and update
    if (![toBeInserted containsObject:obj]) {
        [self willChangeValueForKey:@"hasUnsavedChanges"];
        [toBeUpdated addObject:obj];
        [self didChangeValueForKey:@"hasUnsavedChanges"];
    }
}

- (BOOL)saveChanges:(NSError **)errorPtr {
    [self willChangeValueForKey:@"hasUnsavedChanges"];
    
    FKDataBuffer *buffer = [[FKDataBuffer alloc] initWithCapacity:65536];
    [backend beginTransaction];
    
    // Inserts
    for (FKStoredObject *obj in toBeInserted) {
        Class c = [obj class];
        UInt32 rowID = [obj rowID];
        
        if (usesPerInstanceVersioning) {
            [buffer writeVersionForObject:obj];
        }        
        
        [obj writeContentToBuffer:buffer];
        
        [self encryptBuffer:buffer ofClass:c rowID:rowID]; // does not encrypt if encryptionKey is empty.
        
        [backend insertData:buffer forClass:c rowID:rowID];
        [buffer clearBuffer];
        
        if (indexManager) {
            [indexManager insertObjectInIndexes:obj];
        }
    }
    
    // Updates
    for (FKStoredObject *obj in toBeUpdated) {
        Class c = [obj class];
        UInt32 rowID = [obj rowID];
        if (usesPerInstanceVersioning) {
            [buffer writeVersionForObject:obj];
        }
        
        [obj writeContentToBuffer:buffer];
        
        [self encryptBuffer:buffer ofClass:c rowID:rowID]; // does not encrypt if encryptionKey is empty.
        
        [backend updateData:buffer forClass:c rowID:rowID];
        [buffer clearBuffer];
        
        // FIXME: updating all indexes is inefficient
        if (indexManager) {
            [indexManager updateObjectInIndexes:obj];
        }
    }
    
    // Deletes
    for (FKStoredObject *obj in toBeDeleted) {
        Class c = [obj class];
        UInt32 rowID = [obj rowID];
        
        // Take it out of the uniquing table:
        // Should I remove it from the uniquingTable in deleteObject?
        [uniquingTable removeObjectForClass:c rowID:rowID];
        [obj setStore:nil];
        
        [backend deleteDataForClass:c rowID:rowID];
        
        if (indexManager) {
            [indexManager deleteObjectFromIndexes:obj];
        }
    }
    
    // Write out class meta data
    // FIXME: things will be faster if you only 
    // save ones that have been changed
    int i = 0;
    Class c;
    while ((c = classes[i]) != NULL) {
        FKClassMetaData *d = [classMetaData objectForClass:c];
        if (d) {
            [d writeContentToBuffer:buffer];
            
            [backend updateData:buffer forClass:c rowID:1];
            [buffer clearBuffer];
        }
        i++;
    }
    [buffer release];
    
    BOOL successful = [backend commitTransaction];
    if (successful) {
        [toBeInserted removeAllObjects];
        [toBeUpdated removeAllObjects];
        [toBeDeleted removeAllObjects];
    } else {
        NSLog(@"Error: save was not successful");
        [backend abortTransaction];
    }
    
    [self didChangeValueForKey:@"hasUnsavedChanges"];        
    return successful;
}

#pragma mark Class meta data

- (FKClassMetaData *)metaDataForClass:(Class)c {
    FKClassMetaData *md = [classMetaData objectForClass:c];
    if (!md) {
        md = [[FKClassMetaData alloc] init];
        FKDataBuffer *b;
        b = [backend dataForClass:c 
                            rowID:1];
        
        // Did I find meta data in the database?
        if (b) {
            // Note: meta data data buffer is *not* prepended with a version #
            //NSLog(@"Read %d bytes of meta data for %@", [b length], NSStringFromClass(c));
            [md readContentFromBuffer:b];
            unsigned char classID = [md classID];
            classes[classID] = c;
        } else {
            unsigned char classID = 0;
            while (classes[classID] != c) {
                classID++;
                if (classID == 255) {
                    [NSException raise:@"Class not in classes"
                                format:@"Class %@ was not added to %@", NSStringFromClass(c), self];
                }
            }
            [md setClassID:classID];
        }
        [classMetaData setObject:md forClass:c];
        [md release];
    }
    return md;
}

- (unsigned)nextRowIDForClass:(Class)c {
    FKClassMetaData *md = [self metaDataForClass:c];
    return [md nextPrimaryKey];
}

- (unsigned char)versionForClass:(Class)c {
    FKClassMetaData *md = [self metaDataForClass:c];
    return [md versionNumber];
}

- (Class)classForClassID:(unsigned char)c {
    return classes[c];
}

- (unsigned char)classIDForClass:(Class)c {
    FKClassMetaData *md = [self metaDataForClass:c];
    return [md classID];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<FKStore-%@ to insert:%d, to update %d, to delete %d>",
            backend, [toBeInserted count], [toBeUpdated count], [toBeDeleted count]];
}

@end
