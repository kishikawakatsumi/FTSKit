//
//  FKUniquingTable.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FKStoredObject;

struct UniquingListNode  {
    FKStoredObject *storedObject;
    struct UniquingListNode *next;
};

/*! 
 @class BNRUniquingTable
 @abstract Essentially a dictionary that maps (Class, int) -> BNRStoredObject.  
 (Class, int) pairs must be unique.  It is implemented as a hash table.
 */
// FIXME: this hash table has a fixed number of buckets.  It should grow as the need
// arises
@interface FKUniquingTable : NSObject {
    UInt32 tableSize;
    struct UniquingListNode **table;
}

- (FKStoredObject *)objectForClass:(Class)c rowID:(UInt32)row;
- (void)setObject:(FKStoredObject *)obj forClass:(Class)c rowID:(UInt32)row;
- (void)removeObjectForClass:(Class)c rowID:(UInt32)row;
- (void)makeAllObjectsPerformSelector:(SEL)s;

@end
