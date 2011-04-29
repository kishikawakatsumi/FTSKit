//
//  FKClassDictionary.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class BNRClassDictionary
 @abstract a collection that holds key-value pairs where the key is a Class and
 the values are objects. 
 @discussion Objects are retained.
 */
#ifdef __cplusplus
#include <ext/hash_map>

using std::pair;
using namespace __gnu_cxx;

namespace __gnu_cxx {
    template<>
    struct hash<Class> {
        size_t operator()(const Class ptr) const {
            return (size_t)ptr;
        };
    };
}    

typedef pair<Class, id> HashedPair;
#endif 

@interface FKClassDictionary : NSObject  {
#ifdef __cplusplus
    hash_map<Class, id, hash<Class>, equal_to<Class> > *mapTable;
#else
    void *mapTable; 
#endif
}

/*!
 @method init
 @abstract The designated initializer for this class
 */
- (id)init;

/*!
 @method setObject:forClass
 @abstract Puts the key-value pair into the dictionary.  If the Class is already 
 in the dictionary,  its object is replaced with 'obj'
 @param obj An object
 @param c A Class
 */
- (void)setObject:(id)obj forClass:(Class)c;

/*!
 @method objectForClass:
 @abstract returns the value for the key 'c'
 */
- (id)objectForClass:(Class)c;

@end
