//
//  FKIndexManager.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FKStoredObject;

/*! FKIndexManager is an abstract class. */
@interface FKIndexManager : NSObject

- (UInt32)countOfRowsInClass:(Class)c 
                matchingText:(NSString *)toMatch
                      forKey:(NSString *)key
                        list:(UInt32 **)listptr;
- (uint64_t *)searchResultsInClass:(Class)c 
                      matchingText:(NSString *)toMatch 
                            forKey:(NSString *)key 
                       recordCount:(UInt32 *)recordCount;
- (void)insertObjectInIndexes:(FKStoredObject *)obj;
- (void)deleteObjectFromIndexes:(FKStoredObject *)obj;
- (void)updateObjectInIndexes:(FKStoredObject *)obj;
- (void)close;

@end
