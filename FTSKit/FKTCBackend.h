//
//  FKTCBackend.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKStoreBackend.h"
#include <tcutil.h>
#include <tchdb.h>

#ifdef __cplusplus
#include <ext/hash_map>

using std::pair;
using namespace __gnu_cxx;

namespace __gnu_cxx {
    template<>
    struct hash<Class>
    {
        size_t operator()(const Class ptr) const
        {
            return (size_t)ptr;
        };
    };
}    

typedef pair<Class, TCHDB *> TCFileHashedPair;
#endif 

@interface FKTCBackend : FKStoreBackend {
    NSString *path;
#ifdef __cplusplus
    hash_map<Class, TCHDB *, hash<Class>, equal_to<Class> > *dbTable;
#else
    void *dbTable; 
#endif
    TCHDB *namedBufferDB;
}

- (id)initWithPath:(NSString *)p error:(NSError **)err;
- (TCHDB *)fileForClass:(Class)c;
- (NSString *)path;

@end
