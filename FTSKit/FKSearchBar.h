//
//  FKSearchBar.h
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/29.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    FKSearchTypeStartsWith,
    FKSearchTypeContains,
    FKSearchTypeEndsWith,
    FKSearchTypeMatches
} FKSearchType;

@class FKSearchTextField;
@protocol FKSearchBarDelegate;

@interface FKSearchBar : UINavigationBar <UITextFieldDelegate> {
    FKSearchTextField *searchTextField;
    UIButton *searchTypeButton;
    
    FKSearchType searchType;
    
    id<FKSearchBarDelegate> searchDelegate;
    
    struct {
        unsigned int delegateShouldBeginEditing:1;
        unsigned int delegateShouldEndEditing:1;
        unsigned int delegateTextDidChange:1;
        unsigned int delegateSearchTypeChanged:1;
        unsigned int delegateDoneButtonClicked:1;
    } flags;
}

@property (nonatomic, copy) NSString *text;
@property (nonatomic, readonly) FKSearchType searchType;
@property (nonatomic, assign) id<FKSearchBarDelegate> searchDelegate;

@end

@protocol FKSearchBarDelegate <NSObject>

@optional
- (BOOL)searchBarShouldBeginEditing:(FKSearchBar *)searchBar;
- (BOOL)searchBarShouldEndEditing:(FKSearchBar *)searchBar;
- (void)searchBar:(FKSearchBar *)searchBar textDidChange:(NSString *)searchText;
- (void)searchBarSearchTypeChanged:(FKSearchBar *) searchBar;
- (void)searchBarDoneButtonClicked:(FKSearchBar *) searchBar;

@end
