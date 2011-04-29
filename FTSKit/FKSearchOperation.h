//
//  FKSearchOperation.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/30.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FKSearchBar.h"

@class FKStore;
@class FKResultSet;

@interface FKSearchOperation : NSOperation {
    id delegate;
    
    FKStore *store;
    NSString *searchText;
    FKSearchType searchType;
}

@property (nonatomic, assign) id delegate;

@property (nonatomic, assign) FKStore *store;
@property (nonatomic, retain) NSString *searchText;
@property (nonatomic, assign) FKSearchType searchType;

@end

@protocol FKSearchOperationDelegate <NSObject>

- (void)searchOperaionDidFinished:(FKResultSet *)results;

@end
