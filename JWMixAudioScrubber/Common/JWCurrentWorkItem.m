//
//  JWCurrentWorkItem.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 9/29/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

// A SINGLETON to share infor between controllers

#import "JWCurrentWorkItem.h"


@implementation JWCurrentWorkItem

+ (JWCurrentWorkItem *)sharedInstance
{
    static dispatch_once_t singleton_queue;
    static JWCurrentWorkItem *sharedWorkItem = nil;
    
    dispatch_once(&singleton_queue, ^{
        sharedWorkItem = [[JWCurrentWorkItem alloc] init];
    });
    
    return sharedWorkItem;
}

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

@end
