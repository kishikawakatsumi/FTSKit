//
//  FKResultSet.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/29.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKResultSet.h"
#import "FKStore.h"

@implementation FKResultSet

@synthesize rowCount;
@synthesize rowIDs;

- (id)initWithStore:(FKStore *)s forClass:(Class)c rowCount:(UInt32)count rowIDs:(uint64_t *)rows {
    self = [super init];
    if (self) {
        store = s;
        clazz = c;
        rowCount = count;
        rowIDs = rows;
    }
    return self;
}

- (void)dealloc {
    free(rowIDs);
    [super dealloc];
}

- (FKStoredObject *)objectAtIndex:(NSUInteger)index {
    return [store objectForClass:clazz rowID:rowIDs[index] fetchContent:NO];
}

@end
