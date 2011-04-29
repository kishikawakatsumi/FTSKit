//
//  FKUniquingTable.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKUniquingTable.h"
#import "FKStoredObject.h"

@implementation FKUniquingTable

- (id)init {
    [super init];
    tableSize = 786433;
    //tableSize = 1572869;
    table = (struct UniquingListNode **)calloc(tableSize, sizeof(struct UniquingListNode *));
    return self;
}

- (void)dealloc {
    for (UInt32 i = 0; i < tableSize; i++) {
        struct UniquingListNode *ptr = table[i];
        struct UniquingListNode *nextNode = NULL;
        while (ptr != NULL) {
            FKStoredObject *currentObject = ptr->storedObject;
            nextNode = ptr->next;
            currentObject.store = nil;
            free(ptr);
            ptr = nextNode;
        }
    }
    free(table);
    [super dealloc];
}

- (void)setObject:(FKStoredObject *)obj forClass:(Class)c rowID:(UInt32)row {
    UInt32 bucket = (row + (UInt64)c) % tableSize;
    struct UniquingListNode *ptr = table[bucket];
    struct UniquingListNode *lastPtr = NULL;
    while (ptr != NULL) {
        FKStoredObject *currentObject = ptr->storedObject;
        if ([currentObject rowID] == row && [currentObject class] == c) {
            break;
        }
        lastPtr = ptr;
        ptr = ptr->next;
    }
    if (ptr) {
        ptr->storedObject = obj;
    } else {
        struct UniquingListNode *newNode = (struct UniquingListNode *)malloc(sizeof(struct UniquingListNode));
        newNode->storedObject = obj;
        newNode->next = NULL;
        if (lastPtr) {
            lastPtr->next = newNode;
        } else {
            table[bucket] = newNode;
        }
    }
}

- (FKStoredObject *)objectForClass:(Class)c rowID:(UInt32)row {
    UInt32 bucket = (row + (UInt64)c) % tableSize;
    struct UniquingListNode *ptr = table[bucket];
    while (ptr != NULL) {
        FKStoredObject *currentObject = ptr->storedObject;
        if ([currentObject rowID] == row && [currentObject class] == c) {
            return currentObject;
        }
        ptr = ptr->next;
    }
    return nil;
}

- (void)removeObjectForClass:(Class)c rowID:(UInt32)row {
    UInt32 bucket = (row + (UInt64)c) % tableSize;
    struct UniquingListNode *ptr = table[bucket];
    struct UniquingListNode *previousPtr = NULL;
    while (ptr != NULL) {
        FKStoredObject *currentObject = ptr->storedObject;
        if ([currentObject rowID] == row && [currentObject class] == c) {
            break;
        }
        previousPtr = ptr;
        ptr = ptr->next;
    }
    if (ptr) {
        struct UniquingListNode *nextPtr = ptr->next;
        if (previousPtr) {
            previousPtr->next = nextPtr;
        } else {
            table[bucket] = nextPtr;
        }
        free(ptr);
    }    
}

- (void)makeAllObjectsPerformSelector:(SEL)s {
    for (UInt32 i = 0; i < tableSize; i++) {
        struct UniquingListNode *ptr = table[i];
        while (ptr != NULL) {
            FKStoredObject *currentObject = ptr->storedObject;
            [currentObject performSelector:s];
            ptr = ptr->next;
        }
    }
}

@end
