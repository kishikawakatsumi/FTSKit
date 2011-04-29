//
//  Address.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/30.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "Address.h"
#import "FKDataBuffer.h"

@implementation Address

@synthesize zipcode;
@synthesize full;
@synthesize kana;

+ (NSSet *)textIndexedAttributes {
    static NSSet *textKeys = nil;
    if (!textKeys) {
        textKeys = [[NSSet alloc] initWithObjects:@"zipcode", @"full", @"kana", nil];
    }
    return textKeys;
}

- (void)dealloc {
    self.zipcode = nil;
    self.full = nil;
    self.kana = nil;
    [super dealloc];
}

- (void)readContentFromBuffer:(FKDataBuffer *)d {
    [zipcode release];
    zipcode = [[d readString] retain];
    
    [full release];
    full = [[d readString] retain];
    
    [kana release];
    kana = [[d readString] retain];
}

- (void)writeContentToBuffer:(FKDataBuffer *)d {
    [d writeString:zipcode];
    [d writeString:full];
    [d writeString:kana];
}

- (NSString *)zipcode {
    [self checkForContent];
    return zipcode;
}

- (NSString *)full {
    [self checkForContent];
    return full;
}

- (NSString *)kana {
    [self checkForContent];
    return kana;
}

@end
