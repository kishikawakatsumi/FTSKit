//
//  FKStore.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FKStore;
@class FKStoredObject;
@class FKDataBuffer;
@class FKStoreBackend;
@class FKIndexManager;
@class FKClassDictionary;
@class FKClassMetaData;
@class FKUniquingTable;
@class FKResultSet;

@protocol FKStoreDelegate

- (void)store:(FKStore *)st willInsertObject:(FKStoredObject *)so;
- (void)store:(FKStore *)st willDeleteObject:(FKStoredObject *)so;
- (void)store:(FKStore *)st willUpdateObject:(FKStoredObject *)so;
- (void)store:(FKStore *)st didChangeObject:(FKStoredObject *)so;

@end

#if NS_BLOCKS_AVAILABLE
typedef void(^FKStoredObjectIterBlock)(UInt32 rowID, FKStoredObject *object, BOOL *stop);
#endif

//! FKStore
/*! FKStore is analogous to NSManagedObjectContext.  You use it to fetch, insert
 delete, and update objects to the persistent store. It can have a delegate and an undo
 manager. */
@interface FKStore : NSObject {
    FKUniquingTable *uniquingTable; /**< Maps (Class, rowID) -> BNRStoreddObject */
    
    FKStoreBackend *backend; /**< Actually saves the data */
    
    NSUndoManager *undoManager; /**< If non-nil, undo actions are automatically registered */
    
    FKIndexManager *indexManager; 
    
    id <FKStoreDelegate> delegate; /*< Gets told when an object is to be updated, inserted, or deleted */
    
    // Pending edits are stored in the toBe.. sets
    NSMutableSet *toBeInserted;
    NSMutableSet *toBeDeleted;
    NSMutableSet *toBeUpdated;
    
    // Class meta data
    FKClassDictionary *classMetaData; /*< Maps Class->BNRClassMetaData */
    Class classes[256];  /*< Maps int (the class ID) -> Class */
    
    BOOL usesPerInstanceVersioning; /*< Prepends version number on data buffer; Default = YES */
    
    NSString *encryptionKey; /**< Password to be used in reading and writing objects to/from the store. */
}

@property (nonatomic, retain) FKStoreBackend *backend;
@property (nonatomic, retain) FKIndexManager *indexManager;
@property (nonatomic, retain) NSUndoManager *undoManager;
@property (nonatomic, assign) id <FKStoreDelegate> delegate;
@property (nonatomic, assign) BOOL usesPerInstanceVersioning;
@property (nonatomic, retain) NSString *encryptionKey;

- (id)init;

#pragma mark Fetching

// Fetches the single object of class |c| at row |n|.
// The object's content will be fetched if necessary if |yn| is YES.
// |yn| does not affect any content the object already has.
- (FKStoredObject *)objectForClass:(Class)c rowID:(UInt32)n fetchContent:(BOOL)yn;

// Fetches all stored objects of a particular class.
// All returned objects have content.
- (NSMutableArray *)allObjectsForClass:(Class)c;

// Full-text search
- (NSMutableArray *)objectsForClass:(Class)c matchingText:(NSString *)toMatch forKey:(NSString *)key;

- (NSMutableArray *)objectsForClass:(Class)c mactchesText:text forKey:(NSString *)key;
- (NSMutableArray *)objectsForClass:(Class)c containsText:text forKey:(NSString *)key;
- (NSMutableArray *)objectsForClass:(Class)c beginsWithText:text forKey:(NSString *)key;
- (NSMutableArray *)objectsForClass:(Class)c endsWithText:text forKey:(NSString *)key;

- (FKResultSet *)resultSetForClass:(Class)c matchingText:(NSString *)toMatch forKey:(NSString *)key;

- (FKResultSet *)resultSetForClass:(Class)c mactchesText:(NSString *)text forKey:(NSString *)key;
- (FKResultSet *)resultSetForClass:(Class)c containsText:(NSString *)text forKey:(NSString *)key;
- (FKResultSet *)resultSetForClass:(Class)c beginsWithText:(NSString *)text forKey:(NSString *)key;
- (FKResultSet *)resultSetForClass:(Class)c endsWithText:(NSString *)text forKey:(NSString *)key;

#if NS_BLOCKS_AVAILABLE
- (void)enumerateAllObjectsForClass:(Class)c usingBlock:(FKStoredObjectIterBlock)block;
#endif

#pragma mark Saving

// 'hasUnsavedChanges' is observable
- (BOOL)hasUnsavedChanges;

// Mark object for insertion into object store
- (void)insertObject:(FKStoredObject *)obj;

// Mark object for deletion from object store
- (void)deleteObject:(FKStoredObject *)obj;

// Mark object to be updated in object store
- (void)willUpdateObject:(FKStoredObject *)obj;

- (BOOL)saveChanges:(NSError **)errorPtr;

#pragma mark Class metadata

- (void)addClass:(Class)c;
- (unsigned)nextRowIDForClass:(Class)c;
- (unsigned char)versionForClass:(Class)c;
- (Class)classForClassID:(unsigned char)c;
- (unsigned char)classIDForClass:(Class)c;
- (FKClassMetaData *)metaDataForClass:(Class)c;

#pragma mark Retain-cycle breaking

- (void)dissolveAllRelationships;

@end
