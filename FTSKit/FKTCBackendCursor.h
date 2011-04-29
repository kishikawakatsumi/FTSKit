//
//  FKTCBackendCursor.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FKBackendCursor.h"
#include <tcutil.h>
#include <tchdb.h>

@interface FKTCBackendCursor : FKBackendCursor {
    TCHDB *file;
}

- (id)initWithFile:(TCHDB *)f;

@end
