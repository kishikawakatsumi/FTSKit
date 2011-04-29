//
//  FKStoredObject.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FKStore.h"

/*! FKStoredObject is the superclass for all objects that get saved into the store */
@interface FKStoredObject : NSObject {
    __weak FKStore *store;
    
    // rowID is given out by the store. No other instance
    // of the class will have the same rowID
    UInt32 rowID;
    
    // The least significant bit of status is used for hasContent
    // The other 31 are used for the retain count.
    UInt32 status;
}

@property (nonatomic, assign) FKStore *store;
@property (nonatomic, assign) UInt32 rowID;

#pragma mark Getting data in and out

// readContentFromBuffer: is used during loading
- (void)readContentFromBuffer:(FKDataBuffer *)d;

// writeContentToBuffer: is used during saving
- (void)writeContentToBuffer:(FKDataBuffer *)d;

#pragma mark Versioning

- (UInt8)writeVersion;

#pragma mark Relationships

// prepareForDelete implements delete rules
- (void)prepareForDelete;

// dissolveAllRelationships is for when you are trying to release
// all the objects in the store, but you are worried that there
// might be retain-cycles
- (void)dissolveAllRelationships;

#pragma mark Full-text Indexing

// Should return a set of strings.  Each string is the name of
// a property of a string type
+ (NSSet *)textIndexedAttributes;

#pragma mark Has Content

// Is the object fetched?
- (BOOL)hasContent;
- (void)fetchContent;

// checkForContent is a convenience method that checks to see
// if the object has fetched its data and fetchs it if necessary.
- (void)checkForContent;

@end
