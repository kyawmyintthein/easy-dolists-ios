//
//  ToDoViewController.m
//  EasyDoLists
//
//  Created by Kyaw Myint Thein on 5/7/15.
//  Copyright (c) 2015 com.easydolists. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ToDoViewController.h"
#import "ASWeekSelectorView.h"
#import "BFPaperButton.h"
#import "TaskCell.h"
#import "SCLAlertView.h"

static NSString * const kEDLHome = @"To Do List";

@interface ToDoViewController()<ASWeekSelectorViewDelegate,UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tasksTableView;
@property (strong, nonatomic) IBOutlet ASWeekSelectorView *weekSelector;
@property (strong, nonatomic) NSMutableArray *tasks;
@property (weak, nonatomic) UITextView *todoTextView;

@end


@implementation ToDoViewController
@synthesize weekSelector;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tasks =[[NSMutableArray alloc]init];
    [self.tasks addObjectsFromArray: @[@"To do exercise regulary",@"To eat regularly",@"To sleep regularly"]];
    self.navigationItem.title = kEDLHome;
    NSDate *now = [NSDate date];
    self.weekSelector.firstWeekday = 2; // monday
    self.weekSelector.backgroundColor = [UIColor whiteColor];
    
    self.weekSelector.letterTextColor = [UIColor colorWithWhite:0.5 alpha:1];
    self.weekSelector.delegate = self;
    self.weekSelector.selectedDate = now;
    self.view.backgroundColor = [UIColor colorWithRed: 52.0/255.0f green:152.0/255.0f blue:220.0/255.0f alpha:1.0];
    
//    
//    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStylePlain target:self action:@selector(editButtonPressed:)];
//    editButton.image= [UIImage imageNamed:@"Delete Column Filled-25"];
//    
    UIBarButtonItem *todayButton = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStylePlain target:self action:@selector(todayButtonPressed:)];
    todayButton.image= [UIImage imageNamed:@"Today Filled-25"];
    //self.navigationItem.rightBarButtonItem = editButton;
    self.navigationItem.leftBarButtonItem = todayButton;
    
    BFPaperButton *addNoteButton = [[BFPaperButton alloc] initWithFrame:CGRectMake(116, 468, 70, 70) raised:YES];
    [addNoteButton setTitle:@"Add" forState:UIControlStateNormal];
    [addNoteButton setTitleColor:[UIColor colorWithRed: 52.0/255.0f green:152.0/255.0f blue:220.0/255.0f alpha:1.0] forState:UIControlStateNormal];
    [addNoteButton setTitleColor:[UIColor colorWithRed: 52.0/255.0f green:152.0/255.0f blue:220.0/255.0f alpha:1.0] forState:UIControlStateHighlighted];
    [addNoteButton addTarget:self action:@selector(pressedaddNoteButton:) forControlEvents:UIControlEventTouchUpInside];
    addNoteButton.backgroundColor = [UIColor whiteColor];
    addNoteButton.tapCircleColor = [UIColor colorWithRed:1 green:0 blue:1 alpha:0.6];  // Setting this color overrides "Smart Colo
    addNoteButton.cornerRadius = addNoteButton.frame.size.width / 2;
    addNoteButton.rippleFromTapLocation = NO;
    addNoteButton.rippleBeyondBounds = YES;
    addNoteButton.tapCircleDiameter = MAX(addNoteButton.frame.size.width, addNoteButton.frame.size.height) * 1.3;
    [self.view addSubview:addNoteButton];
    
   
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tasksTableView.backgroundColor = [UIColor clearColor];
    self.tasksTableView.dataSource = self;
    self.tasksTableView.delegate = self;
    self.tasksTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tasksTableView.allowsMultipleSelectionDuringEditing = NO;

}


- (IBAction)pressedaddNoteButton:(id)sender {
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    
    alert.customViewColor =[UIColor colorWithRed: 52.0/255.0f green:152.0/255.0f blue:220.0/255.0f alpha:1.0];
    
    self.todoTextView =[alert addTextView:@"Add your task here"];
   
//    [self.todoTextView becomeFirstResponder];
    [alert addButton:@"Done" actionBlock:^(void) {
//        [self saveNote];
    }];
    
    
    [alert showEdit:self title:@"Add Note" subTitle:@"" closeButtonTitle:@"Close" duration:0.0f];
    
//    [self.todoTextView becomeFirstResponder];   
}

- (void)todayButtonPressed:(UIBarButtonItem *)sender
{
    NSDate *now = [NSDate date];
    [self.weekSelector setSelectedDate:now animated:YES];
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tasksTableView setEditing:editing animated:YES];
    
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
}
#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.tasks.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TaskCell *taskCell;

    static NSString *cellIdentifier = @"TaskCell";

    taskCell = (TaskCell *)[self.tasksTableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    taskCell.taskName.text = self.tasks[indexPath.row];
    taskCell.backgroundColor = [UIColor clearColor];
    taskCell.taskName.numberOfLines = 0;
    taskCell.taskName.textColor = [UIColor whiteColor];
    taskCell.textLabel.font=[UIFont fontWithName:@"Aileron-Bold" size:18.0];
    taskCell.selectionStyle = UITableViewCellSelectionStyleNone;
    return taskCell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55;
}


// Override to support conditional editing of the table view.
// This only needs to be implemented if you are going to be returning NO
// for some items. By default, all items are editable.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"delete");
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.tasks removeObjectAtIndex:indexPath.row];
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView reloadData];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Value Selected by user
//    TaskCell *selectedCell=(TaskCell*)[tableView cellForRowAtIndexPath:indexPath];
//    [selectedCell flatRoundedButtonPressed];
//
    
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    NSString *stringToMove = [self.tasks objectAtIndex:sourceIndexPath.row];
    [self.tasks removeObjectAtIndex:sourceIndexPath.row];
    [self.tasks insertObject:stringToMove atIndex:destinationIndexPath.row];
}



- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

//- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
//       toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
//    NSDictionary *section = [self.tasks objectAtIndex:sourceIndexPath.section];
//    NSUInteger sectionCount = [[section valueForKey:@"content"] count];
//    if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
//        NSUInteger rowInSourceSection =
//        (sourceIndexPath.section > proposedDestinationIndexPath.section) ?
//        0 : sectionCount - 1;
//        return [NSIndexPath indexPathForRow:rowInSourceSection inSection:sourceIndexPath.section];
//    } else if (proposedDestinationIndexPath.row >= sectionCount) {
//        return [NSIndexPath indexPathForRow:sectionCount - 1 inSection:sourceIndexPath.section];
//    }
//    // Allow the proposed destination.
//    return proposedDestinationIndexPath;
//}



@end
