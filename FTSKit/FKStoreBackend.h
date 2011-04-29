//
//  FKStoreBackend.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FKBackendCursor;
@class FKDataBuffer;

/*! FKStoreBackend is an abstract class.  The concrete subclass uses a particular
 key-value store.  At different times, these subclasses have used BerkeleyDB, 
 GDBM, and TokyoCabinent.  I think Tokyo Tyrant would be a fun next experiment.
 */
@interface FKStoreBackend : NSObject

#pragma mark Transaction support

- (BOOL)beginTransaction;
- (BOOL)commitTransaction;
- (BOOL)abortTransaction;
- (BOOL)hasOpenTransaction;

#pragma mark Writing changes

- (void)insertData:(FKDataBuffer *)d forClass:(Class)c rowID:(UInt32)n;
- (void)deleteDataForClass:(Class)c rowID:(UInt32)n;
- (void)updateData:(FKDataBuffer *)d forClass:(Class)c rowID:(UInt32)n;

#pragma mark Named buffers

- (void)insertDataBuffer:(FKDataBuffer *)value forName:(NSString *)key;
- (void)deleteDataBufferForName:(NSString *)key;
- (void)updateDataBuffer:(FKDataBuffer *)d forName:(NSString *)key;
- (NSSet *)allNames;
- (FKDataBuffer *)dataBufferForName:(NSString *)key;

#pragma mark Fetching

- (FKDataBuffer *)dataForClass:(Class)c rowID:(UInt32)n;
- (FKBackendCursor *)cursorForClass:(Class)c;

- (void)close;

@end
