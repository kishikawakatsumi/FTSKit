//
//  FKIndexManager.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKIndexManager.h"

@implementation FKIndexManager

- (UInt32)countOfRowsInClass:(Class)c 
                matchingText:(NSString *)toMatch
                      forKey:(NSString *)key
                        list:(UInt32 **)listptr {
    return 0; 
}

- (uint64_t *)searchResultsInClass:(Class)c 
                      matchingText:(NSString *)toMatch 
                            forKey:(NSString *)key 
                       recordCount:(UInt32 *)recordCount {
    *recordCount = 0;
    return NULL;
}

- (void)insertObjectInIndexes:(FKStoredObject *)obj {
    
}

- (void)deleteObjectFromIndexes:(FKStoredObject *)obj {
    
}

- (void)updateObjectInIndexes:(FKStoredObject *)obj {
    
}

- (void)close {
    
}

@end
