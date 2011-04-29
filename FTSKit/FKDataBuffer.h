//
//  FKDataBuffer.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FKStoredObject;
@class FKStore;

/*!
 @class BNRDataBuffer
 @abstract used for reading and writing blobs of data that come from the backend
 @discussion Everything is kept in little-endian order for best performance on 
 Intel machines.
 */
@interface FKDataBuffer : NSObject {
    unsigned char *buffer;
    unsigned int capacity;
    
    unsigned int length;
    unsigned char *cursor;
    UInt8 versionOfData; // Set by consumeVersion, see -[FKStore usesPerInstanceVersioning];
}

@property (nonatomic, assign, readonly) unsigned char *buffer;
@property (nonatomic, assign, readonly) unsigned int capacity;
@property (nonatomic, assign, readwrite) unsigned int length;
@property (nonatomic, assign, readonly) UInt8 versionOfData;

/*!
 @method initWithCapacity:
 @abstract Used to create empty buffers (typically then written to)
 */
- (id)initWithCapacity:(NSUInteger)c;

/*!
 @method initWithData:length:
 @abstract Used to create full buffers (typically then read from)
 */
- (id)initWithData:(void *)v length:(unsigned)size;

/*!
 @method setData:length:
 @abstract Used to create full buffers (typically then read from)
 */
- (void)setData:(void *)v length:(unsigned)size;

/*!
 @method resetCursor
 @abstract Moves the cursor back to the beginning of the buffer
 */
- (void)resetCursor;

/*!
 @method clearBuffer
 @abstract Moves the cursor back to the beginning of the buffer and
 sets the length to zero
 */
- (void)clearBuffer;

- (UInt8)readUInt8;
- (void)writeUInt8:(UInt8)x;

- (UInt32)readUInt32;
- (void)writeUInt32:(UInt32)x;

- (Float32)readFloat32;
- (void)writeFloat32:(Float32)f;

- (Float64)readFloat64;
- (void)writeFloat64:(Float64)f;

- (FKStoredObject *)readObjectReferenceOfClass:(Class)c usingStore:(FKStore *)s;
- (void)writeObjectReference:(FKStoredObject *)obj;

- (FKStoredObject *)readObjectReferenceOfUnknownClassUsingStore:(FKStore *)s;
- (void)writeObjectReferenceOfUnknownClass:(FKStoredObject *)obj usingStore:(FKStore *)s;

- (NSMutableArray *)readArrayOfClass:(Class)c usingStore:(FKStore *)s;
- (void)writeArray:(NSArray *)a ofClass:(Class)c;

- (NSMutableArray *)readHeteroArrayUsingStore:(FKStore *)s;
- (void)writeHeteroArray:(NSArray *)a usingStore:(FKStore *)s;

- (id)readArchiveableObject;
- (void)writeArchiveableObject:(id)obj;

- (NSString *)readString;
- (void)writeString:(NSString *)s;

- (NSData *)readData;
- (void)writeData:(NSData *)d;

- (NSDate *)readDate;
- (void)writeDate:(NSDate *)d;

- (void)copyFrom:(const void *)d length:(size_t)byteCount;

- (void)consumeVersion;
- (void)writeVersionForObject:(FKStoredObject *)obj;

@end
