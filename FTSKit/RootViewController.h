//
//  RootViewController.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FKSearchBar.h"

@class FKStore;
@class FKResultSet;

@interface RootViewController : UIViewController
<UITableViewDataSource, UITableViewDelegate, FKSearchBarDelegate> {
    UITableView *listView;
    
    NSOperationQueue *queue;
    
    FKStore *store;
    FKResultSet *resultSet;
}

@property (nonatomic, retain) NSOperationQueue *queue;

@property (nonatomic, retain) FKStore *store;
@property (nonatomic, retain) FKResultSet *resultSet;

@end
