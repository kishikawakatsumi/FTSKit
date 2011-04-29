//
//  FKStoreBackend.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKStoreBackend.h"

@implementation FKStoreBackend

#pragma mark Transaction support

- (BOOL)beginTransaction {
    return NO;
}

- (BOOL)commitTransaction {
    return NO;
}

- (BOOL)abortTransaction {
    return NO;
}

- (BOOL)hasOpenTransaction {
    return NO;
}

#pragma mark Writing changes

- (void)insertData:(FKDataBuffer *)attNames forClass:(Class)c rowID:(UInt32)n {
    NSLog(@"insertData:forClass:rowID: not defined for %@", self);
}

- (void)deleteDataForClass:(Class)c rowID:(UInt32)n {
    NSLog(@"deleteDataForClass:rowID: not defined for %@", self);
}

- (void)updateData:(FKDataBuffer *)d forClass:(Class)c  rowID:(UInt32)n {
    NSLog(@"updateData:forClass:rowID: not defined for %@", self);
}

#pragma mark Named buffers

- (void)insertDataBuffer:(FKDataBuffer *)value forName:(NSString *)key {
    NSLog(@"insertDataBuffer:forName: not defined for %@", self);
}

- (void)deleteDataBufferForName:(NSString *)key {
    NSLog(@"deleteDataBufferForName: not defined for %@", self);
}

- (void)updateDataBuffer:(FKDataBuffer *)d forName:(NSString *)key {
    NSLog(@"updateDataBuffer:forName: not defined for %@", self);
}

- (NSSet *)allNames {
    NSLog(@"allNames not defined for %@", self);
    return nil;
}

- (FKDataBuffer *)dataBufferForName:(NSString *)key {
    NSLog(@"dataBufferForName: not defined for %@", self);
    return nil;
}

#pragma mark Fetching

- (FKDataBuffer *)dataForClass:(Class)c rowID:(UInt32)n {
    return nil;
}

- (FKBackendCursor *)cursorForClass:(Class)c {
    return nil;
}

- (void)close {
    
}

@end
