//
//  FKTCIndexManager.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FKIndexManager.h"
#include <dystopia.h>

@interface FKTCIndexManager : FKIndexManager {
    NSString *path;
    NSMutableDictionary *textIndexes;
}

- (id)initWithPath:(NSString *)p error:(NSError **)err;
- (TCIDB *)textIndexForClass:(Class)c key:(NSString *)k;
- (NSString *)path;
- (void)close;

@end
