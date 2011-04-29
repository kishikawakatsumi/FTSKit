//
//  FKResultSet.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/29.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FKStore;
@class FKStoredObject;

@interface FKResultSet : NSObject {
    FKStore *store;
    Class clazz;
    
    UInt32 rowCount;
    uint64_t *rowIDs;
}

@property (nonatomic, readonly) UInt32 rowCount;
@property (nonatomic, readonly) uint64_t *rowIDs;

- (id)initWithStore:(FKStore *)s forClass:(Class)c rowCount:(UInt32)count rowIDs:(uint64_t *)rows;
- (FKStoredObject *)objectAtIndex:(NSUInteger)index;

@end
