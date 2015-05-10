//
//  Task.h
//  EasyDoLists
//
//  Created by Kyaw Myint Thein on 5/10/15.
//  Copyright (c) 2015 com.easydolists. All rights reserved.
//

#import <Realm/Realm.h>

@interface Task : RLMObject
@property  NSString *id;
@property NSString *note;
@property  NSString *shortDescription;
@property  NSDate *createdAt;
@property NSDate *createdFor;
@property BOOL isDone;
@property BOOL isAlert;
@end

// This protocol enables typed collections. i.e.:
// RLMArray<Task>
RLM_ARRAY_TYPE(Task)
