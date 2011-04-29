//
//  RootViewController.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "RootViewController.h"
#import "FKStore.h"
#import "FKTCBackend.h"
#import "FKTCIndexManager.h"
#import "FKResultSet.h"
#import "FKSearchOperation.h"
#import "Address.h"

@implementation RootViewController

@synthesize queue;
@synthesize store;
@synthesize resultSet;

- (void)dealloc {
    [queue cancelAllOperations];
    self.queue = nil;
    self.store = nil;
    self.resultSet = nil;
    [super dealloc];
}

- (void)loadView {
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 416.0f)];
    self.view = contentView;
    [contentView release];
    
    listView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 416.0f)];
    listView.dataSource = self;
    listView.delegate = self;
    [contentView addSubview:listView];
    [listView release];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    FKSearchBar *searchBar = [[FKSearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
    searchBar.searchDelegate = self;
    [self.navigationController.navigationBar addSubview:searchBar];
    [searchBar release];
    
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dataPath = [documentDirectory stringByAppendingPathComponent:@"Data"];
    NSFileManager *fm = [[NSFileManager alloc] init];
    if (![fm fileExistsAtPath:dataPath]) {
        NSString *src = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Data"];
        [fm copyItemAtPath:src toPath:dataPath error:nil];
    }
    
    self.store = [[[FKStore alloc] init] autorelease];
    
    FKTCBackend *backend = [[FKTCBackend alloc] initWithPath:dataPath error:nil];
    [store setBackend:backend];
    [backend release];
    
    FKTCIndexManager *indexManager = [[FKTCIndexManager alloc] initWithPath:dataPath error:nil];
    [store setIndexManager:indexManager];
    [indexManager release];
    
    [store addClass:[Address class]];
    
    self.queue = [[[NSOperationQueue alloc] init] autorelease];
    [queue setMaxConcurrentOperationCount:1];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [queue cancelAllOperations];
    self.queue = nil;
    self.store = nil;
    self.resultSet = nil;
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return resultSet.rowCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    UInt32 rowCount = resultSet.rowCount; 
    if (rowCount > 0) {
        return [NSString stringWithFormat:@"%d %@ / %d", rowCount, NSLocalizedString(@"results", nil), 147196];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    NSUInteger row = indexPath.row;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    }
    
    Address *address = (Address *)[resultSet objectAtIndex:row];
    
    cell.textLabel.text = address.full;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@ %@", [NSString stringWithUTF8String:"〒"], address.zipcode, address.kana];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)searchWithSearchBar:(FKSearchBar *)searchBar {
    [queue cancelAllOperations];
    
    NSString *searchText = searchBar.text;
    if ([searchText length] == 0) {
        self.resultSet = nil;
        [listView reloadData];
        return;
    }
    
    FKSearchOperation *searchOperation = [[FKSearchOperation alloc] init];
    searchOperation.delegate = self;
    searchOperation.store = store;
    searchOperation.searchText = searchText;
    searchOperation.searchType = searchBar.searchType;
    
    [queue addOperation:searchOperation];
    [searchOperation release];
}

- (void)searchOperaionDidFinished:(FKResultSet *)results {
    self.resultSet = results;
    [listView reloadData];
}

- (void)searchBar:(FKSearchBar *)searchBar textDidChange:(NSString *)searchText {  
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(searchWithSearchBar:) withObject:searchBar afterDelay:0.2];
}

- (void)searchBarSearchTypeChanged:(FKSearchBar *)searchBar {
    [self searchWithSearchBar:searchBar];
}

@end
