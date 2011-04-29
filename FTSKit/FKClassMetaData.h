//
//  FKClassMetaData.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FKDataBuffer;

/*!
 @const kFKMetadataRowID
 @abstract Defines the row ID where class metadata are stored.
 */
#define kFKMetadataRowID (1)

/*! 
 @class FKClassMetaData
 @abstract Holds onto the classID, the last primary key given out, and
 the version number of the class.
 @discussion The information necessary for the store to get objects into and out
 of the backend.  In particular, each object going into the store needs a unique rowID (or
 primary key). The rowIDs are unique for that class.  The version number is
 there so that in readContentFromBuffer: an object can figure out what version the
 data was written in.  The classID is written to the stream when you need to know which
 class is in the store.
 
 rowIDs will start at 2 because the database doesn't allow record 0 and record 1 contains
 this class meta data.
 
 FKClassMetaData are kept in a FKClassDictionary, so they don't actually have the 
 Class itself.
 */
@interface FKClassMetaData : NSObject {
    // These attributes are stored as record 1 in the database
    // for the class
    unsigned char classID;
    volatile UInt32 lastPrimaryKey;
    unsigned char versionNumber;
    UInt32 encryptionKeySalt[2];
}

/*!
 @method classID
 @abstract Returns the class's ID
 @discussion Each class in the store has a different classID.  Note that we can only
 handle 256 classes.
 */
- (unsigned char)classID;

/*!
 @method setClassID:
 @abstract For setting the class's ID
 */
- (void)setClassID:(unsigned char)x;

/*!
 @method nextPrimaryKey
 @abstract Returns a unique row ID for that class
 @discussion This method increments the lastPrimaryKey and returns it.
 Threadsafe.
 */
- (UInt32)nextPrimaryKey;

/*!
 @method versionNumber
 @abstract returns the version of the class that is in the backend
 */
- (unsigned char)versionNumber;

/*!
 @method setVersionNumber:
 @abstract Called before saving to record version number of the data
 */
- (void)setVersionNumber:(unsigned char)x;

/*!
 @method readContentFromBuffer:
 @abstract Called automatically when the meta data is first read in from the backend
 */
- (void)readContentFromBuffer:(FKDataBuffer *)d;

/*!
 @method writeContentToBuffer:
 @abstract Called automatically when the meta data is being written out
 */
- (void)writeContentToBuffer:(FKDataBuffer *)d;

/*!
 @method encryptionKeySalt
 @abstract Returns the encryption key salt value used on with this class's data.
 */
- (const UInt32 *)encryptionKeySalt;

@end
