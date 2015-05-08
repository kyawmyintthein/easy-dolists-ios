//
//  ToDoViewController.m
//  EasyDoLists
//
//  Created by Kyaw Myint Thein on 5/7/15.
//  Copyright (c) 2015 com.easydolists. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ToDoViewController.h"
//#import "ASWeekSelectorView.h"
#import "BFPaperButton.h"
#import "TaskCell.h"
#import "SCLAlertView.h"
#import "JTCalendar.h"
static NSString * const kEDLHome = @"To Do List";

@interface ToDoViewController()<UITableViewDataSource,UITableViewDelegate,JTCalendarDataSource>
@property (strong, nonatomic) IBOutlet UIButton *changeModeButton;
@property (strong, nonatomic) IBOutlet UITableView *tasksTableView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet JTCalendarMenuView *weeMenuView;
@property (strong, nonatomic) NSMutableArray *tasks;
@property (weak, nonatomic) UITextView *todoTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *calendarContentViewHeight;
@property (strong, nonatomic) IBOutlet JTCalendarContentView *calendarContentView;
@property (strong, nonatomic) JTCalendar *calendar;

@end


@implementation ToDoViewController
//@synthesize weekSelector;
 NSMutableDictionary *eventsByDate;
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tasks =[[NSMutableArray alloc]init];
    [self.tasks addObjectsFromArray: @[@"To do exercise regulary",@"To eat regularly",@"To sleep regularly",@"To do exercise regulary",@"To eat regularly",@"To sleep regularly",@"To do exercise regulary",@"To eat regularly",@"To sleep regularly",@"To do exercise regulary",@"To eat regularly",@"To sleep regularly",@"To do exercise regulary",@"To eat regularly",@"To sleep regularly"]];
    self.navigationItem.title = kEDLHome;

    self.changeModeButton.tintColor = [UIColor colorWithRed: 52.0/255.0f green:152.0/255.0f blue:220.0/255.0f alpha:1.0];
    self.changeModeButton.titleLabel.text = @"Chage Calendar View";
    self.calendar = [JTCalendar new];
    // All modifications on calendarAppearance have to be done before setMenuMonthsView and setContentView
    // Or you will have to call reloadAppearance
    {
        self.calendar.calendarAppearance.calendar.firstWeekday = 2; // Sunday == 1, Saturday == 7
        self.calendar.calendarAppearance.dayCircleRatio = 9. / 10.;
        self.calendar.calendarAppearance.ratioContentMenu = 2.;
        self.calendar.calendarAppearance.focusSelectedDayChangeMode = YES;
        self.calendar.calendarAppearance.isWeekMode = YES;
        self.calendar.calendarAppearance.menuMonthTextColor =[UIColor whiteColor];
        
        // Customize the text for each month
        self.calendar.calendarAppearance.monthBlock = ^NSString *(NSDate *date, JTCalendar *jt_calendar){
            NSCalendar *calendar = jt_calendar.calendarAppearance.calendar;
            NSDateComponents *comps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:date];
            NSInteger currentMonthIndex = comps.month;
            
            static NSDateFormatter *dateFormatter;
            if(!dateFormatter){
                dateFormatter = [NSDateFormatter new];
                dateFormatter.timeZone = jt_calendar.calendarAppearance.calendar.timeZone;
            }
            
            while(currentMonthIndex <= 0){
                currentMonthIndex += 12;
            }
            
            NSString *monthText = [[dateFormatter standaloneMonthSymbols][currentMonthIndex - 1] capitalizedString];
            
            return [NSString stringWithFormat:@"%ld\n%@", comps.year, monthText];
        };
    }
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.bounds.size.width, self.scrollView.bounds.size.height*3)];

    [self.calendar setMenuMonthsView:self.weeMenuView];
    [self.calendar setContentView:self.calendarContentView];
    [self.calendar setDataSource:self];
    [self createRandomEvents];
    [self.calendar reloadData];
    self.view.backgroundColor = [UIColor colorWithRed: 52.0/255.0f green:152.0/255.0f blue:220.0/255.0f alpha:1.0];

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
    
//    self.calendarContentViewHeight.constant = 75;
//    [self.calendarContentView addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarContentView
//                                                       attribute:NSLayoutAttributeHeight
//                                                       relatedBy:NSLayoutRelationEqual
//                                                          toItem:nil
//                                                       attribute:NSLayoutAttributeNotAnAttribute
//                                                      multiplier:1.0
//                                                        constant:74.0]];
//    [self.calendarContentView reloadAppearance];
//    [self.calendarContentView setContentSize:CGSizeMake(self.scrollView.frame.size.width,75)];
//    [self.calendarContentView addConstraint:self.calendarContentViewHeight];
    NSLog(@"dfa %@",self.calendarContentView.constraints);

}

-(void) viewDidAppear:(BOOL)animated{
   [self transitionExample];
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
 //   [self.weekSelector setSelectedDate:now animated:YES];
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


- (IBAction)didGoTodayTouch
{
    [self.calendar setCurrentDate:[NSDate date]];
}

- (IBAction)didChangeModeTouch
{
    self.calendar.calendarAppearance.isWeekMode = !self.calendar.calendarAppearance.isWeekMode;
    [self transitionExample];
}

#pragma mark - JTCalendarDataSource

- (BOOL)calendarHaveEvent:(JTCalendar *)calendar date:(NSDate *)date
{
    NSString *key = [[self dateFormatter] stringFromDate:date];
    
    if(eventsByDate[key] && [eventsByDate[key] count] > 0){
        return YES;
    }
    
    return NO;
}

- (void)calendarDidDateSelected:(JTCalendar *)calendar date:(NSDate *)date
{
    NSString *key = [[self dateFormatter] stringFromDate:date];
    NSArray *events = eventsByDate[key];
    
    NSLog(@"Date: %@ - %ld events", date, [events count]);
}

- (void)calendarDidLoadPreviousPage
{
    NSLog(@"Previous page loaded");
}

- (void)calendarDidLoadNextPage
{
    NSLog(@"Next page loaded");
}

#pragma mark - Transition examples

- (void)transitionExample
{
    [self.calendarContentView removeConstraints:self.calendarContentView.constraints];
    CGFloat newHeight = 300;
    if(self.calendar.calendarAppearance.isWeekMode){
        newHeight = 75;
    }
    
    [UIView animateWithDuration:.5
                     animations:^{
//                         self.calendarContentViewHeight.constant = newHeight;
                         [self.calendarContentView addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarContentView
                                                                                              attribute:NSLayoutAttributeHeight
                                                                                              relatedBy:NSLayoutRelationEqual
                                                                                                 toItem:nil
                                                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                                                             multiplier:1.0
                                                                                               constant:newHeight]];
                            [self.view layoutIfNeeded];
                         
//                         [self.tasksTableView addConstraint:[NSLayoutConstraint constraintWithItem:self.tasksTableView
//                                                                                              attribute:NSLayoutAttributeTop
//                                                                                              relatedBy:NSLayoutRelationEqual
//                                                                                                 toItem:self.calendarContentView
//                                                                                              attribute:NSLayoutAttributeNotAnAttribute
//                                                                                             multiplier:1.0
//                                                                                               constant:10]];
                         [self.view layoutIfNeeded];
                        
                     }];
    
    [UIView animateWithDuration:.25
                     animations:^{
                         self.calendarContentView.layer.opacity = 0;
                     }
                     completion:^(BOOL finished) {
                         [self.calendar reloadAppearance];
                         
                         [UIView animateWithDuration:.25
                                          animations:^{
                                              self.calendarContentView.layer.opacity = 1;
                                          }];
                     }];
     NSLog(@"dfa %@",self.calendarContentView.constraints);
}

#pragma mark - Fake data

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"dd-MM-yyyy";
    }
    
    return dateFormatter;
}

- (void)createRandomEvents
{
    eventsByDate = [NSMutableDictionary new];
    
    for(int i = 0; i < 30; ++i){
        // Generate 30 random dates between now and 60 days later
        NSDate *randomDate = [NSDate dateWithTimeInterval:(rand() % (3600 * 24 * 60)) sinceDate:[NSDate date]];
        
        // Use the date as key for eventsByDate
        NSString *key = [[self dateFormatter] stringFromDate:randomDate];
        
        if(!eventsByDate[key]){
            eventsByDate[key] = [NSMutableArray new];
        }
        
        [eventsByDate[key] addObject:randomDate];
    }
}


@end
