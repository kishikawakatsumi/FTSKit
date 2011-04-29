//
//  FKSearchBar.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/29.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKSearchBar.h"

static UIImage *background;

@interface FKSearchTextField : UITextField
@end

@implementation FKSearchTextField

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.background = [[UIImage imageNamed:@"search_textfield_bg.png"] stretchableImageWithLeftCapWidth:30 topCapHeight:0];
        
        self.leftView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"search.png"]] autorelease];
        self.leftViewMode = UITextFieldViewModeAlways;
        self.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        self.returnKeyType = UIReturnKeyDone;
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectMake(100.0f, 6.0f, 176.0f, 30.0f);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectMake(100.0f, 6.0f, 124.0f, 30.0f);
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds {
    return CGRectMake(78.0f, 9.0f, 16.0f, 16.0f);
}

- (CGRect)clearButtonRectForBounds:(CGRect)bounds {
    return CGRectMake(227.0f, 7.0f, 19.0f, 19.0f);
}

@end

@interface FKSearchBar(Private)

- (void)updateSearchTypeButton;

@end

@implementation FKSearchBar

@synthesize text;
@synthesize searchType;
@synthesize searchDelegate;

+ (void)initialize {
    background = [[UIImage imageNamed: @"searchbar_bg.png"] retain];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UINavigationItem *item = [[UINavigationItem alloc] init];
        self.items = [NSArray arrayWithObject:item];
        [item release];
        
        searchTextField = [[FKSearchTextField alloc] initWithFrame:CGRectMake(8.0f, 6.0f, 304.0f, 30.0f)];
        searchTextField.delegate = self;
        [searchTextField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
        [self addSubview:searchTextField];
        [searchTextField release];
        
        searchTypeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        searchTypeButton.frame = CGRectMake(0.0f, 1.0f, 72.0f, 30.0f);
        searchTypeButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0f];
        searchTypeButton.titleLabel.textColor = [UIColor whiteColor];
        searchTypeButton.titleEdgeInsets = UIEdgeInsetsMake(2.0f, -6.0f, 0.0f, 0.0f);
        searchTypeButton.exclusiveTouch = YES;
        [searchTypeButton setBackgroundImage:[UIImage imageNamed:@"searchtype_bg.png"] forState:UIControlStateNormal];
        [searchTypeButton addTarget:self action:@selector(toggleSearchType:) forControlEvents:UIControlEventTouchUpInside];
        [searchTextField addSubview:searchTypeButton];
        
        [self updateSearchTypeButton];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [background drawAtPoint:CGPointZero];
}

- (NSString *)text {
    return searchTextField.text;
}

- (void)setText:(NSString *)t {
    searchTextField.text = t;
}

- (void)setSearchDelegate:(id<FKSearchBarDelegate>)delegate {
    searchDelegate = delegate;
    flags.delegateShouldBeginEditing = [delegate respondsToSelector:@selector(searchBarShouldBeginEditing:)];
    flags.delegateShouldEndEditing = [delegate respondsToSelector:@selector(searchBarShouldEndEditing:)];
    flags.delegateTextDidChange = [delegate respondsToSelector:@selector(searchBar:textDidChange:)];
    flags.delegateSearchTypeChanged = [delegate respondsToSelector:@selector(searchBarSearchTypeChanged:)];
    flags.delegateDoneButtonClicked = [delegate respondsToSelector:@selector(searchBarDoneButtonClicked:)];
}

#pragma mark -

- (void)updateSearchTypeButton {
    switch (searchType) {
        case FKSearchTypeStartsWith:
            [searchTypeButton setTitle:NSLocalizedString(@"Starts with", nil) forState:UIControlStateNormal];
            break;
            
        case FKSearchTypeContains:
            [searchTypeButton setTitle:NSLocalizedString(@"Contains", nil) forState:UIControlStateNormal];
            break;
            
        case FKSearchTypeEndsWith:
            [searchTypeButton setTitle:NSLocalizedString(@"Ends with", nil) forState:UIControlStateNormal];
            break;
            
        case FKSearchTypeMatches:
            [searchTypeButton setTitle:NSLocalizedString(@"Matches", nil) forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}

- (void)toggleSearchType:(id)sender {
    searchType++;
    if (searchType > FKSearchTypeMatches) {
        searchType = FKSearchTypeStartsWith;
    }
    [self updateSearchTypeButton];
    
    if (flags.delegateSearchTypeChanged) {
        [searchDelegate searchBarSearchTypeChanged:self];
    }
}

#pragma mark -

- (void)done:(id)sender {
    [searchTextField resignFirstResponder];
    
    if (flags.delegateDoneButtonClicked) {
        [searchDelegate searchBarDoneButtonClicked:self];
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (flags.delegateShouldBeginEditing) {
        if (![searchDelegate searchBarShouldBeginEditing:self]) {
            return NO;
        }
    }
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    [self.topItem setRightBarButtonItem:doneButton animated:YES];
    [doneButton release];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    searchTextField.frame = CGRectMake(8.0f, 6.0f, 252.0f, 30.0f);    
    [UIView commitAnimations];
    
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if (flags.delegateShouldEndEditing) {
        if (![searchDelegate searchBarShouldEndEditing:self]) {
            return NO;
        }
    }
    
    [self.topItem setRightBarButtonItem:nil animated:YES];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    searchTextField.frame = CGRectMake(8.0f, 6.0f, 304.0f, 30.0f);
    [UIView commitAnimations];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self done:nil];
    return YES;
}

- (void)textDidChange:(id)sender {
    if (flags.delegateTextDidChange) {
        [searchDelegate searchBar:self textDidChange:searchTextField.text];
    }
}

@end
