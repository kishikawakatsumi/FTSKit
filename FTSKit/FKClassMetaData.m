//
//  FKClassMetaData.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKClassMetaData.h"
#import "FKDataBuffer.h"
#import "FKCrypto.h"
#import <libkern/OSAtomic.h>

@implementation FKClassMetaData

- (id)init {
    [super init];
    // Primary keys start at 2
    lastPrimaryKey = 1;
    versionNumber = 1;
    classID = 0;
    
    // Randomize the salt to start with; if a class is being loaded the salt will be set in -readContentFromBuffer:.
    FKRandomBytes(encryptionKeySalt, 8);
    
    return self;
}

- (unsigned char)classID {
    return classID;
}

- (void)setClassID:(unsigned char)x {
    classID = x;
}

- (UInt32)nextPrimaryKey {
    // FIXME: Write AtomicIncrementUInt32Barrier() using Atomic C&S.
    UInt32 nextPrimaryKey = (UInt32)OSAtomicIncrement32Barrier((volatile int32_t *)&lastPrimaryKey);
    return nextPrimaryKey;
}

- (unsigned char)versionNumber {
    return versionNumber;
}

- (void)setVersionNumber:(unsigned char)x {
    versionNumber = x;
}

- (void)readContentFromBuffer:(FKDataBuffer *)d {
    lastPrimaryKey = [d readUInt32];
    versionNumber = [d readUInt8];
    classID = [d readUInt8];
    if ([d length] > 6) {
        for (int i = 0; i < 2; i++)
            encryptionKeySalt[i] = [d readUInt32];
    }
    
}

- (void)writeContentToBuffer:(FKDataBuffer *)d {
    [d writeUInt32:lastPrimaryKey];
    [d writeUInt8:versionNumber];
    [d writeUInt8:classID];
    for (int i = 0; i < 2; i++) {
        [d writeUInt32:encryptionKeySalt[i]];
    }
}

- (const UInt32 *)encryptionKeySalt {
    return encryptionKeySalt;
}

@end
