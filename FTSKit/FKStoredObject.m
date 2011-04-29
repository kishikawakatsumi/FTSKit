//
//  FKStoredObject.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKStoredObject.h"
#import "FKStoreBackend.h"
#import "FKDataBuffer.h"
#import "FKDataBuffer+Encryption.h"
#import "FKClassMetaData.h"
#import "FKUniquingTable.h"

@interface FKStore (FKStoredObjectFriend)

- (FKUniquingTable *)uniquingTable;

@end

@implementation FKStore (FKStoredObjectFriend)

- (FKUniquingTable *)uniquingTable {
    return uniquingTable;
}

@end

@implementation FKStoredObject

@synthesize store;
@synthesize rowID;

// NOT the designated initializer, just a convenience for BNRStore.
- (id)initWithStore:(FKStore *)s rowID:(UInt32)n buffer:(FKDataBuffer *)buffer {
    self = [self init];
    // Known to return non-nil, so no test.
    store = s;
    rowID = n;
    if (nil != buffer) {
        if ([s usesPerInstanceVersioning]) {
            [buffer consumeVersion];
        }
        
        [self readContentFromBuffer:buffer];
        // Retain count of 1 + 1 for hasContent
        status = 3;
    } else {
        // Retain count of 1 
        status = 2;
    }
    return self;
}

- (id)init {
    [super init];
    // Retain count of 1 + hasContent
    status = 3;
    return self;
}

#pragma mark Getting data in and out

- (void)readContentFromBuffer:(FKDataBuffer *)d {
    // NOOP, must be overridden by subclass
}

- (void)writeContentToBuffer:(FKDataBuffer *)d {
    // NOOP, must be overridden by subclass
}

#pragma mark Versioning

- (UInt8)writeVersion {
    return (UInt8)[[self class] version];
}

#pragma mark Relationships

- (void)dissolveAllRelationships {
    // NOOP, may be overridden by subclass
}

- (void)prepareForDelete {
    // NOOP, may be overridden by subclass 
}

#pragma mark Full-text Indexing

+ (NSSet *)textIndexedAttributes {
    return nil;
}

#pragma mark Has Content

- (BOOL)hasContent {
    return status % 2;
}

- (void)setHasContent:(BOOL)yn {
    // Do I currently have content?
    if ([self hasContent]) {
        if (yn == NO) {
            status--;  // just lost content
        }
    } else if (yn == YES) {
        status++;  // just gained content
    }
}

- (void)fetchContent {
    if (0U == rowID) {
        return;
    }
    
    FKStore *s = [self store];
    FKStoreBackend *backend = [s backend];
    FKDataBuffer *d = [backend dataForClass:[self class] rowID:[self rowID]];
    if (!d) {
        return;
    }
    
    FKClassMetaData *metaData = [s metaDataForClass:[self class]];
    [d decryptWithKey:[s encryptionKey] salt:[metaData encryptionKeySalt]];
    
    if ([s usesPerInstanceVersioning]) {
        [d consumeVersion];
    }
    [self readContentFromBuffer:d];
    [self setHasContent:YES];
}

- (void)checkForContent {
    if (![self hasContent]) {
        [self fetchContent];
    }
}

- (NSUInteger)retainCount {
    return status / 2;
}

- (id)retain {
    status += 2;
    return self;
}

- (oneway void)release {
    status -= 2;
    if (status < 2) [self dealloc];
}

- (void)dealloc {
    FKUniquingTable *uniquingTable = [store uniquingTable];
    [uniquingTable removeObjectForClass:[self class] rowID:[self rowID]];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: rowID = %lu>", NSStringFromClass([self class]), [self rowID]];
}

@end
