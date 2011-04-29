//
//  FKDataBuffer+Encryption.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FKDataBuffer.h"

@interface FKDataBuffer (Encryption)

- (BOOL)decryptWithKey:(NSString *)key salt:(const UInt32 *)salt;
- (void)encryptWithKey:(NSString *)key salt:(const UInt32 *)salt;

@end
