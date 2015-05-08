//
//  TaskCell.h
//  EasyDoLists
//
//  Created by Kyaw Myint Thein on 5/7/15.
//  Copyright (c) 2015 com.easydolists. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VBFPopFlatButton.h"
@interface TaskCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *taskName;
@property (strong, nonatomic) VBFPopFlatButton *doneButton;
@property (strong, nonatomic) UIButton *alertButton;
@property(assign) bool isDone;
@property(assign) bool isAlert;
-(void) flatRoundedButtonPressed;
@end
