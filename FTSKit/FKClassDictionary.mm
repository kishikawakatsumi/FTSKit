//
//  FKClassDictionary.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKClassDictionary.h"

@implementation FKClassDictionary

- (id)init {
    [super init];
    mapTable = new hash_map<Class, id, hash<Class>, equal_to<Class> >(389);
    return self;
}

- (void)dealloc {
    delete mapTable;
    [super dealloc];
}

- (void)setObject:(id)obj forClass:(Class)c {
    // NSMapInsert(mapTable, c, obj);
    id oldValue = (*mapTable)[c];
    if (oldValue == obj) {
        return;
    }
    [obj retain];
    [oldValue release];
    (*mapTable)[c] = obj;
}

- (id)objectForClass:(Class)c {
    return (*mapTable)[c];
}

@end
