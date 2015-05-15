//
//  Task.m
//  EasyDoLists
//
//  Created by Kyaw Myint Thein on 5/10/15.
//  Copyright (c) 2015 com.easydolists. All rights reserved.
//

#import "Task.h"

@implementation Task


+ (NSDictionary *)defaultPropertyValues
{
    return @{@"note" : @"",
             @"shortDescription" : @"",
             @"createdAt" : [NSDate date]};
}

+ (NSString *)primaryKey {
    return @"id";
}

- (NSComparisonResult)compare:(Task *)otherObject {
    return [self.id compare:otherObject.id];
}

// Specify default values for properties

//+ (NSDictionary *)defaultPropertyValues
//{
//    return @{};
//}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

@end
