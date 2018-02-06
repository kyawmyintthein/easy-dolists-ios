//
//  ToDoViewController.h
//  EasyDoLists
//
//  Created by Kyaw Myint Thein on 5/7/15.
//  Copyright (c) 2015 com.easydolists. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditTextField.h"

@interface TaskTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet EditTextField *customTitleLabel;

@property (nonatomic, copy) void (^additionButtonTapAction)(id sender);
@property (nonatomic, copy) void (^editButtonTapAction)(id sender);
@property (nonatomic) BOOL additionButtonHidden;

- (void)setupWithTitle:(NSString *)title detailText:(NSString *)detailText level:(NSInteger)level additionButtonHidden:(BOOL)additionButtonHidden;
- (void)setAdditionButtonHidden:(BOOL)additionButtonHidden animated:(BOOL)animated;

@end
