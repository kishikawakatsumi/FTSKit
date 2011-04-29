//
//  Address.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/30.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FKStoredObject.h"

@interface Address : FKStoredObject {
    NSString *zipcode;
    NSString *full;
    NSString *kana;
}

@property (nonatomic, retain) NSString *zipcode;
@property (nonatomic, retain) NSString *full;
@property (nonatomic, retain) NSString *kana;

@end
