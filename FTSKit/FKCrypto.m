//
//  FKCrypto.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKCrypto.h"

#if TARGET_OS_IPHONE // iPhone:

#import <Security/Security.h>

void FKRandomBytes(void *buffer, int length) {
    SecRandomCopyBytes(kSecRandomDefault, length, (uint8_t *)buffer);
}

#else // Mac:

#import <openssl/rand.h>
#import <libkern/OSTypes.h>

void FKRandomBytes(void *buffer, int length) {
    RAND_pseudo_bytes((UInt8 *)buffer, length);
}

#endif
