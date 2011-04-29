//
//  FKBackendCursor.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FKDataBuffer;

/*! 
 @class FKBackendCursor
 @abstract This is an abstract class.  When a backend returns a collection
 key-data pairs, it returns a FKBackendCursor
 */
@interface FKBackendCursor : NSObject

/*!
 @method nextBuffer:
 @abstract returns the key and fills the buffer 'c' with the associated data.
 @discussion This method is called repeatedly until it returns 0.
 @param c An empty databuffer to be filled with data
 */
- (UInt32)nextBuffer:(FKDataBuffer *)c;

@end
