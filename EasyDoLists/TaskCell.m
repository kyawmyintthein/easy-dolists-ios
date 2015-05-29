//
//  TaskCell.m
//  EasyDoLists
//
//  Created by Kyaw Myint Thein on 5/7/15.
//  Copyright (c) 2015 com.easydolists. All rights reserved.
//

#import "TaskCell.h"
#import "VBFPopFlatButton.h"
#import "UIColor+FlatColors.h"
@implementation TaskCell
- (id)initWithCoder:(NSCoder *)coder
{
    
    self = [super initWithCoder:coder];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        if (self.doneButton) {
            [self.doneButton addTarget:self
                                action:@selector(doneButtonPressed)
             
                      forControlEvents:UIControlEventTouchUpInside];
        }
        if (self.alertButton) {
            [self.alertButton addTarget:self action:@selector(alertButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        }

    }
    
    return self;
}

- (void) doneButtonPressed {
    NSLog(@"Button pressed");
    if (self.isDone) {
        [self.doneButton animateToType:buttonOkType];
        self.isDone = false;
    }else{
        [self.doneButton animateToType:buttonSquareType];
        self.isDone = true;
    }
    
}

- (void) alertButtonPressed {
    NSLog(@"Alert pressed");
    if (self.isAlert) {
        UIImage *image =[UIImage imageNamed:@"timer18"];
        [self.alertButton setImage:image forState:UIControlStateNormal];
        self.isAlert = false;
    }else{
        [self.alertButton setImage:[UIImage imageNamed:@"timer18"] forState:UIControlStateNormal];
         self.alertButton.imageView.tintColor =[UIColor whiteColor];
        self.isAlert = true;
    }
    
}



@end
