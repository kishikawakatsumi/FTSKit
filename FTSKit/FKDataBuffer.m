//
//  FKDataBuffer.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKDataBuffer.h"
#import "FKStore.h"
#import "FKStoredObject.h"

@implementation FKDataBuffer

@synthesize buffer;
@synthesize capacity;
@synthesize length;
@synthesize versionOfData;

- (id)initWithCapacity:(NSUInteger)c {
    [super init];
    buffer = (unsigned char *)malloc(c);
    cursor = buffer;
    capacity = c;
    return self;
}

- (id)initWithData:(void *)v length:(unsigned)size {
    [super init];
    [self setData:v length:size];
    return self;
}

- (void)setData:(void *)v length:(unsigned)size {
    if (buffer) {
        free(buffer);
    }
    buffer = v;
    cursor = buffer;
    length = size;
    capacity = size;    
}

- (void)dealloc {
    free(buffer);
    [super dealloc];
}

- (void)grow {
    NSLog(@"growing");
    unsigned newCapacity;
    
    if (capacity < 256) {
        newCapacity = 512;
    } else {
        newCapacity = capacity * 2;
    }
    ptrdiff_t offset = cursor - buffer;
    unsigned char *newBuffer = (unsigned char *)malloc(newCapacity);
    memcpy(newBuffer, buffer, length);
    cursor = newBuffer + offset;
    capacity = newCapacity;
    free(buffer);
    buffer = newBuffer;
}

- (void)checkForSpaceFor:(unsigned int)bytesComing {
    while (capacity < cursor - buffer + bytesComing) {
        [self grow];
    }
}

- (void)resetCursor {
    cursor = buffer;
}

- (void)clearBuffer {
    length = 0;
    cursor = buffer;
}

- (UInt8)readUInt8 {
    UInt8 result;
    memcpy(&result, cursor, sizeof(UInt8));
    cursor += sizeof(UInt8);
    return result;
}

- (void)writeUInt8:(UInt8)x {
    [self checkForSpaceFor:sizeof(UInt32)];
    memcpy(cursor, &x, sizeof(UInt8));
    cursor += sizeof(UInt8);   
    length += sizeof(UInt8);
}

- (UInt32)readUInt32 {
    UInt32 result;
    memcpy(&result, cursor, sizeof(UInt32));
    cursor += sizeof(UInt32);
    return CFSwapInt32LittleToHost(result);
}

- (void)writeUInt32:(UInt32)x {
    [self checkForSpaceFor:sizeof(UInt32)];
    
    UInt32 swapped = CFSwapInt32HostToLittle(x);
    memcpy(cursor, &swapped, sizeof(UInt32));
    cursor += sizeof(UInt32);   
    length += sizeof(UInt32);
}

- (Float32)readFloat32 {
    CFSwappedFloat32 result;
    memcpy(&result, cursor, sizeof(CFSwappedFloat32));
    cursor += sizeof(CFSwappedFloat32);
    return CFConvertFloatSwappedToHost(result);
}

- (void)writeFloat32:(Float32)f {
    [self checkForSpaceFor:sizeof(CFSwappedFloat32)];
    CFSwappedFloat32 s;
    s = CFConvertFloatHostToSwapped(f);
    memcpy(cursor, &s, sizeof(CFSwappedFloat32));
    cursor += sizeof(CFSwappedFloat32);   
    length += sizeof(CFSwappedFloat32);
}

- (Float64)readFloat64 {
    CFSwappedFloat64 result;
    memcpy(&result, cursor, sizeof(CFSwappedFloat64));
    cursor += sizeof(CFSwappedFloat64);
    return CFConvertDoubleSwappedToHost(result);
}

- (void)writeFloat64:(Float64)f {
    [self checkForSpaceFor:sizeof(CFSwappedFloat64)];
    CFSwappedFloat64 s;
    s = CFConvertDoubleHostToSwapped(f);
    memcpy(cursor, &s, sizeof(CFSwappedFloat64));
    cursor += sizeof(CFSwappedFloat64);   
    length += sizeof(CFSwappedFloat64);
}

- (FKStoredObject *)readObjectReferenceOfClass:(Class)c usingStore:(FKStore *)s {
    UInt32 rowID = [self readUInt32];
    if (rowID == 0) {
        NSLog(@"reading nil object reference");
        return nil;
    }
    FKStoredObject *obj = [s objectForClass:c rowID:rowID fetchContent:NO];
    return obj;
}

- (void)writeObjectReference:(FKStoredObject *)obj {
    UInt32 rowID = [obj rowID];
    [self writeUInt32:rowID];
}

- (FKStoredObject *)readObjectReferenceOfUnknownClassUsingStore:(FKStore *)s {
    unsigned char classID = [self readUInt8];
    Class c = [s classForClassID:classID];
    return [self readObjectReferenceOfClass:c
                                 usingStore:s];
}

- (void)writeObjectReferenceOfUnknownClass:(FKStoredObject *)obj usingStore:(FKStore *)s {
    Class c = [obj class];
    unsigned char classID = [s classIDForClass:c];
    [self writeUInt8:classID];
    [self writeObjectReference:obj];
}

- (NSMutableArray *)readArrayOfClass:(Class)c usingStore:(FKStore *)s {
    // FIXME: I suspect that this could also be made faster with 
    // clever multithreading
    UInt32 len = [self readUInt32];
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:len];
    [result autorelease];
    int i;
    for (i = 0; i < len; i++) {
        FKStoredObject *obj = [self readObjectReferenceOfClass:c usingStore:s];
        if (obj) {
            [result addObject:obj];
        } else {
            NSLog(@"Fetched nil for object %d in array.  Skipping.", i);
        }
    }
    return result;
}

- (void)writeArray:(NSArray *)a ofClass:(Class)c {
    UInt32 len = [a count];
    [self writeUInt32:len];
    int i;
    for (i = 0; i < len; i++) {
        FKStoredObject *obj = [a objectAtIndex:i];
        [self writeObjectReference:obj];
    }
}

- (NSMutableArray *)readHeteroArrayUsingStore:(FKStore *)s {
    UInt32 len = [self readUInt32];
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:len];
    [result autorelease];
    int i;
    for (i = 0; i < len; i++) {
        FKStoredObject *obj = [self readObjectReferenceOfUnknownClassUsingStore:s];
        [result addObject:obj];
    }
    return result;
}

- (void)writeHeteroArray:(NSArray *)a usingStore:(FKStore *)s {
    UInt32 len = [a count];
    [self writeUInt32:len];
    int i;
    for (i = 0; i < len; i++) {
        FKStoredObject *obj = [a objectAtIndex:i];
        [self writeObjectReferenceOfUnknownClass:obj usingStore:s];
    }
}

- (id)readArchiveableObject {
    NSData *d = [self readData];
    id result = [NSKeyedUnarchiver unarchiveObjectWithData:d];
    return result;
}

- (void)writeArchiveableObject:(id)obj {
    NSData *d = [NSKeyedArchiver archivedDataWithRootObject:obj];
    [self writeData:d];
}

- (NSString *)readString {
    unsigned dLen = [self readUInt32];
    if (dLen == 0) {
        return nil;
    }
    NSString *d = [[NSString alloc] initWithBytes:cursor length:dLen encoding:NSUTF8StringEncoding];
    cursor += dLen;
    return [d autorelease];
}

- (void)writeString:(NSString *)s {
    UInt32 dLen = [s lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    [self writeUInt32:dLen];
    
    if (dLen != 0) {
        [self checkForSpaceFor:dLen];
        BOOL success = [s getBytes:cursor
                         maxLength:dLen
                        usedLength:NULL
                          encoding:NSUTF8StringEncoding
                           options:0
                             range:NSMakeRange(0, [s length])
                    remainingRange:NULL];
        if (!success) {
            NSLog(@"failed to write any characters");
        }
        
        cursor += dLen;
        length += dLen;
    }
}

- (NSData *)readData {
    unsigned dLen = [self readUInt32];
    if (dLen == 0) {
        return nil;
    }
    NSData *d = [NSData dataWithBytes:cursor length:dLen];
    cursor += dLen;
    return d;
}

- (void)writeData:(NSData *)d {
    unsigned dLen = [d length];
    [self writeUInt32:dLen];
    if (dLen != 0) {
        [self copyFrom:[d bytes] length:dLen];
    }
}

- (NSDate *)readDate {
    Float64 timeInterval = [self readFloat64];
    return [NSDate dateWithTimeIntervalSinceReferenceDate:timeInterval];
}

- (void)writeDate:(NSDate *)d {
    Float64 timeInterval = [d timeIntervalSinceReferenceDate];
    [self writeFloat64:timeInterval];
}

- (void)copyFrom:(const void *)d length:(size_t)byteCount {
    [self checkForSpaceFor:byteCount];
    
    memcpy(cursor, d, byteCount);
    cursor += byteCount;
    length += byteCount;
    
}

- (void)consumeVersion {
    versionOfData = [self readUInt8];
}

- (void)writeVersionForObject:(FKStoredObject *)obj {
    versionOfData = [obj writeVersion];
    [self writeUInt8:versionOfData];
}

- (NSString *)description {
    NSMutableString *result = [NSMutableString stringWithFormat:@"<FKDataBuffer %d bytes:", [self length]];
    unsigned char *cptr = buffer;
    while (cptr - buffer < length) {
        [result appendFormat:@"%x.", *cptr];
        cptr++;
    }
    return result;
}

@end
