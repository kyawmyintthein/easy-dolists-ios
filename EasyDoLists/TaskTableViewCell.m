//
//  ToDoViewController.h
//  EasyDoLists
//
//  Created by Kyaw Myint Thein on 5/7/15.
//  Copyright (c) 2015 com.easydolists. All rights reserved.
//

#import "TaskTableViewCell.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface TaskTableViewCell ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *additionButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

@end

@implementation TaskTableViewCell

- (void)awakeFromNib
{
  [super awakeFromNib];
  
  self.selectedBackgroundView = [UIView new];
  self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
  
}

- (void)prepareForReuse
{
  [super prepareForReuse];
  
  self.additionButtonHidden = NO;
}


- (void)setupWithTitle:(NSString *)title detailText:(NSString *)detailText level:(NSInteger)level additionButtonHidden:(BOOL)additionButtonHidden
{
  self.customTitleLabel.text = title;
  self.additionButtonHidden = additionButtonHidden;
  
  if (level == 0) {
    self.detailTextLabel.textColor = [UIColor blackColor];
  }
  
  if (level == 0) {
    self.backgroundColor = UIColorFromRGB(0xF7F7F7);
  } else if (level == 1) {
    self.backgroundColor = UIColorFromRGB(0xD1EEFC);
  } else if (level >= 2) {
    self.backgroundColor = UIColorFromRGB(0xE0F8D8);
  }
  
  CGFloat left = 11 + 20 * level;
  
  CGRect titleFrame = self.customTitleLabel.frame;
  titleFrame.origin.x = left;
  self.customTitleLabel.frame = titleFrame;
}


#pragma mark - Properties

- (void)setAdditionButtonHidden:(BOOL)additionButtonHidden
{
  [self setAdditionButtonHidden:additionButtonHidden animated:NO];
}

- (void)setAdditionButtonHidden:(BOOL)additionButtonHidden animated:(BOOL)animated
{
  _additionButtonHidden = additionButtonHidden;
  [UIView animateWithDuration:animated ? 0.2 : 0 animations:^{
    self.additionButton.hidden = additionButtonHidden;
  }];
}

#pragma mark - Actions

- (IBAction)additionButtonTapped:(id)sender
{
  if (self.additionButtonTapAction) {
    self.additionButtonTapAction(sender);
  }
}

- (IBAction)editButtonTapped:(id)sender {
    
    if (self.editButtonTapAction) {
        self.editButtonTapAction(sender);
    }
}

@end
