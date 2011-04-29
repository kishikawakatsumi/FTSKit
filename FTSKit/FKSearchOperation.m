//
//  FKSearchOperation.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/30.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FKSearchOperation.h"
#import "FKStore.h"
#import "FKResultSet.h"
#import "Address.h"

@implementation FKSearchOperation

@synthesize delegate;
@synthesize store;
@synthesize searchText;
@synthesize searchType;

- (void)dealloc {
    self.searchText = nil;
    [super dealloc];
}

- (void)main {
    if (!self.isCancelled) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        if (!self.isCancelled) {
            NSString *text = searchText;
            
            NSMutableString *toKana = [NSMutableString stringWithString:text];
            CFRange range = CFRangeMake(0, [text length]);
            CFStringTransform((CFMutableStringRef)toKana, &range, kCFStringTransformHiraganaKatakana, false);
            text = toKana;
            
            NSString *key = @"kana";
            
            FKResultSet *resultSet;
            if (searchType == FKSearchTypeStartsWith) {
                resultSet = [store resultSetForClass:[Address class] beginsWithText:text forKey:key];
            } else if (searchType == FKSearchTypeEndsWith) {
                resultSet = [store resultSetForClass:[Address class] endsWithText:text forKey:key];
            } else if (searchType == FKSearchTypeContains) {
                resultSet = [store resultSetForClass:[Address class] containsText:text forKey:key];
            } else {
                resultSet = [store resultSetForClass:[Address class] mactchesText:text forKey:key];
            }
            
            [delegate performSelectorOnMainThread:@selector(searchOperaionDidFinished:) withObject:resultSet waitUntilDone:YES];
        }
        
        [pool release];
    }
}

@end
