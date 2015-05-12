//
//  ToDoViewController.m
//  EasyDoLists
//
//  Created by Kyaw Myint Thein on 5/7/15.
//  Copyright (c) 2015 com.easydolists. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ToDoViewController.h"
#import "BFPaperButton.h"
#import "TaskCell.h"
#import "SCLAlertView.h"
#import "JTCalendar.h"
#import <Realm/Realm.h>
#import "Task.h"
#import "UIScrollView+UzysCircularProgressPullToRefresh.h"
#import "DateTools.h"
#import "ActionSheetDatePicker.h"
#import "NZAlertView.h"
static NSString * const kEDLHome = @"To Do List";

@interface ToDoViewController()<UITableViewDataSource,UITableViewDelegate,JTCalendarDataSource>
@property (strong, nonatomic) IBOutlet UIButton *changeModeButton;
@property (strong, nonatomic) IBOutlet UITableView *tasksTableView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet JTCalendarMenuView *weeMenuView;
@property (strong, nonatomic) RLMArray *tasks;
@property (weak, nonatomic) UITextView *todoTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *calendarContentViewHeight;
@property (strong, nonatomic) IBOutlet JTCalendarContentView *calendarContentView;
@property (strong, nonatomic) JTCalendar *calendar;
@property (strong,nonatomic) Task *selectedTask;
@property (nonatomic, strong) RLMNotificationToken *notification;

@end


@implementation ToDoViewController
//@synthesize weekSelector;
 NSMutableDictionary *eventsByDate;
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = kEDLHome;

    self.changeModeButton.tintColor = [UIColor colorWithRed: 52.0/255.0f green:152.0/255.0f blue:220.0/255.0f alpha:1.0];
    self.changeModeButton.titleLabel.text = @"Chage Calendar View";
    self.calendar = [JTCalendar new];
//    NSDateFormatter *dateFormatters = [[NSDateFormatter alloc] init];
//    [dateFormatters setDateFormat:@"dd-MMM-yyyy"];
//    [dateFormatters setDateStyle:NSDateFormatterShortStyle];
//    [dateFormatters setTimeStyle:NSDateFormatterShortStyle];
//    [dateFormatters setDoesRelativeDateFormatting:YES];
//    [dateFormatters setTimeZone:[NSTimeZone systemTimeZone]];
    [self.calendar.calendarAppearance.calendar setTimeZone:[NSTimeZone systemTimeZone]];
    // All modifications on calendarAppearance have to be done before setMenuMonthsView and setContentView
    // Or you will have to call reloadAppearance
    {
        self.calendar.calendarAppearance.calendar.firstWeekday = 2; // Sunday == 1, Saturday == 7
        self.calendar.calendarAppearance.dayCircleRatio = 9. / 10.;
        self.calendar.calendarAppearance.ratioContentMenu = 1.;
        self.calendar.calendarAppearance.focusSelectedDayChangeMode = YES;
        self.calendar.calendarAppearance.isWeekMode = YES;
        self.calendar.currentDateSelected = [NSDate date];
        self.calendar.calendarAppearance.menuMonthTextColor =[UIColor whiteColor];
    
        
        // Customize the text for each month
        self.calendar.calendarAppearance.monthBlock = ^NSString *(NSDate *date, JTCalendar *jt_calendar){
            NSCalendar *calendar = jt_calendar.calendarAppearance.calendar;
//            [jt_calendar.calendarAppearance.calendar setTimeZone:[NSTimeZone systemTimeZone]];
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
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.bounds.size.width, self.scrollView.bounds.size.height*1.5)];

    [self.calendar setMenuMonthsView:self.weeMenuView];
    [self.calendar setContentView:self.calendarContentView];
    [self.calendar setDataSource:self];
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

    [self loadTasks];
    __weak typeof(self) weakSelf = self;
    
    self.notification = [RLMRealm.defaultRealm addNotificationBlock:^(NSString *note, RLMRealm *realm) {
        [weakSelf loadTasks];
    }];
    
    [self.tasksTableView addPullToRefreshActionHandler:^{
        [weakSelf loadTasks];
    }];

    [self.tasksTableView reloadData];
    

    
}

-(void)viewWillAppear:(BOOL)animated{
    [self loadTasks];
    [self.tasksTableView reloadData];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self transitionMode];
//    [self reloadTasks];
//    [self.tasksTableView reloadData];
    [self.tasksTableView becomeFirstResponder];
}

- (void)loadTasks{
    int daysToAdd = 1;
    NSDate *curretDate = [[NSDate new] dateBySubtractingDays:1];
    NSDate *newDate1 = [curretDate dateByAddingDays:daysToAdd];
    NSString *stringForPredicate = @"(createdFor >=  %@) and (createdFor < %@)";
    NSPredicate* filterPredicate = [NSPredicate predicateWithFormat:stringForPredicate, curretDate,newDate1];
    self.tasks = [[Task objectsWithPredicate:filterPredicate] sortedResultsUsingProperty:@"id" ascending:YES];


}

- (void)reloadTasks{
    int daysToAdd = 1;
    NSDate *newDate1 = [self.calendar.currentDateSelected dateByAddingTimeInterval:60*60*24*daysToAdd];
    NSString *stringForPredicate = @"(createdFor >=  %@) and (createdFor < %@)";
    NSPredicate* filterPredicate = [NSPredicate predicateWithFormat:stringForPredicate, self.calendar.currentDateSelected,newDate1];
    self.tasks = [[Task objectsWithPredicate:filterPredicate] sortedResultsUsingProperty:@"id" ascending:YES];
    NSLog(@"order %@",self.tasks);
}

- (BOOL*)reloadTasksByDate:(NSDate*)selectedDate{
    int daysToAdd = 1;
    NSDate *newDate1 = [selectedDate dateByAddingTimeInterval:60*60*24*daysToAdd];
    NSString *stringForPredicate = @"(createdFor >=  %@) and (createdFor < %@)";
    NSPredicate* filterPredicate = [NSPredicate predicateWithFormat:stringForPredicate, selectedDate,newDate1];
    if ([Task objectsWithPredicate:filterPredicate].count > 0) {
        return true;
    }
    return false;
}

- (void)addTask:(NSString *)note createdFor:(NSDate*) createdFor{
    RLMRealm *realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];
    Task *task = [[Task alloc] init];
    RLMArray *tasks = [[Task allObjects]  sortedResultsUsingProperty:@"id" ascending:YES] ;
    Task *lastTask = nil;
    NSLog(@"task coutn %@",tasks);
    if (tasks.count  >= 1) {
        lastTask = tasks[(tasks.count -1)];
       
        int *lastId = [lastTask.id intValue];
        int *newId =(int)lastId + [@1 intValue];
        task.id =  [NSString stringWithFormat:@"%i",(int)newId];
    }else{
        task.id = @"1";
    }

    task.note = note;
    task.createdAt = [NSDate date];
    task.createdFor = createdFor;
    task.isDone = false;
    task.isAlert = false;
    [realm addObject:task];
    [realm commitWriteTransaction];
    [self reloadTasks];
    [self.tasksTableView reloadData];
}

-(void)updateTask:(Task *)task isDone:(BOOL*)isDone isAlert:(BOOL*)isAlert{

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    task.isDone = isDone;
    task.isAlert = isAlert;
    Task *updateTask = [Task createOrUpdateInDefaultRealmWithObject:task];
    [realm addOrUpdateObject:updateTask];
    [realm commitWriteTransaction];
//    [self reloadTasks];
//    [self.tasksTableView reloadData];
//    NZAlertView *alert = [[NZAlertView alloc] initWithStyle:NZAlertStyleSuccess
//                                                      title:@"Success!"
//                                                    message:@"Task is updated."
//                                                   delegate:nil];
//    
//    [alert setTextAlignment:NSTextAlignmentCenter];
//    
//    [alert show];
//    
//    [alert showWithCompletion:^{
//        NSLog(@"Alert with completion handler");
//    }];
//

}



-(void)deleteTask:(Task *)task{
    RLMRealm *realm = RLMRealm.defaultRealm;
    // Updating book with id = 1
    [realm beginWriteTransaction];
    [realm deleteObject:task];
    [realm commitWriteTransaction];
    [self reloadTasks];
    [self.tasksTableView reloadData];
//    [self.tasksTableView reloadData];
//    NZAlertView *alert = [[NZAlertView alloc] initWithStyle:NZAlertStyleSuccess
//                                                      title:@"Success!"
//                                                    message:@"Task is deleted."
//                                                   delegate:nil];
//    
//    [alert setTextAlignment:NSTextAlignmentCenter];
//    
//    [alert show];
//    
//    [alert showWithCompletion:^{
//        NSLog(@"Alert with completion handler");
//    }];

}




- (IBAction)pressedaddNoteButton:(id)sender {
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    
    alert.customViewColor =[UIColor colorWithRed: 52.0/255.0f green:152.0/255.0f blue:220.0/255.0f alpha:1.0];
    
    self.todoTextView =[alert addTextView:@"Add your task here"];
   
//    [self.todoTextView becomeFirstResponder];
    [alert addButton:@"Done" actionBlock:^(void) {
        if (self.calendar.currentDateSelected) {
            [self addTask:self.todoTextView.text createdFor:self.calendar.currentDateSelected];
        }else{
            [self addTask:self.todoTextView.text createdFor:self.calendar.currentDate];
        }
        
    }];
    [alert showEdit:self title:@"Add Task" subTitle:@"" closeButtonTitle:@"Close" duration:0.0f];
    [self reloadTasks];
    [self.tasksTableView reloadData];
}

- (void)todayButtonPressed:(UIBarButtonItem *)sender
{

    [self.calendar setCurrentDate:[NSDate date]];
    [self.calendar setCurrentDateSelected:[NSDate date]];
    [self reloadTasks];
    [self.tasksTableView reloadData];
    
}

- (void)pressedDoneButton:(UIBarButtonItem *)sender
{
    Task *task = [self.tasks objectAtIndex:sender.tag];
    NSLog(@"task %@",task.id);
   NSLog(task.isDone ? @"Yes" : @"No");
   [self updateTask:task isDone:YES isAlert:task.isAlert];
    [self reloadTasks];
    [self.tasksTableView reloadData];
    
}


-(void)timeWasSelected:(NSDate *)selectedTime{


    // create a local notification
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:self.selectedTask.createdFor];
    
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    [components setHour:[selectedTime hour]];
    [components setMinute:[selectedTime minute]];
    NSDate *notiDatetime = [calendar dateFromComponents:components];
    
    notification.fireDate = notiDatetime;
    notification.timeZone = [NSTimeZone systemTimeZone];
    notification.repeatInterval = NSCalendarUnitMinute;
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.alertAction = @"Ok";
    notification.alertBody =self.selectedTask.note;
    
    [self updateTask:self.selectedTask isDone:false isAlert:true];
    [self reloadTasks];
    
    [[UIApplication sharedApplication]scheduleLocalNotification:notification];
}

- (void)pressedAlertButton:(UIButton *)sender
{
    Task *task = [self.tasks objectAtIndex:sender.tag];
    if (task.isAlert) {
        [self updateTask:task isDone:task.isDone isAlert:false];
    }else{
        self.selectedTask = task;
        ActionSheetDatePicker *datePicker = [[ActionSheetDatePicker alloc] initWithTitle:@"Set Time for Reminder" datePickerMode:UIDatePickerModeTime selectedDate:[NSDate date] target:self action:@selector(timeWasSelected:) origin:sender];
        [datePicker setTimeZone:[NSTimeZone systemTimeZone]];
        UIView *bgView = [[UIView alloc]init];
        bgView.backgroundColor = [UIColor redColor];
        
        datePicker.minuteInterval = 5;
        [datePicker setPickerView:bgView];
        [datePicker showActionSheetPicker];
        

    }
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
    Task *task = [self.tasks objectAtIndex:indexPath.row];
    taskCell.taskName.text = task.note;
    taskCell.backgroundColor = [UIColor clearColor];
    taskCell.taskName.numberOfLines = 0;
    taskCell.taskName.textColor = [UIColor whiteColor];
    taskCell.textLabel.font=[UIFont fontWithName:@"Aileron-Bold" size:18.0];
    taskCell.selectionStyle = UITableViewCellSelectionStyleNone;
    taskCell.doneButton.tag = indexPath.row;
    taskCell.alertButton.tag = indexPath.row;
    taskCell.showsReorderControl = YES;
    if (task.isDone) {
        [taskCell.doneButton animateToType:buttonOkType];
    }else{
        [taskCell.doneButton animateToType:buttonSquareType];

    }
    
    if (task.isAlert) {
        UIImage *image =[UIImage imageNamed:@"Alarm Clock Filled-25"];
        [taskCell.alertButton setImage:image forState:UIControlStateNormal];
    }else{
        UIImage *image =[UIImage imageNamed:@"Alarm Clock-25"];
        [taskCell.alertButton setImage:image forState:UIControlStateNormal];
    }
    
    [taskCell.doneButton addTarget:self action:@selector(pressedDoneButton:) forControlEvents:UIControlEventTouchUpInside];
    [taskCell.alertButton addTarget:self action:@selector(pressedAlertButton:) forControlEvents:UIControlEventTouchUpInside];
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
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //[self.tasks removeObjectAtIndex:indexPath.row];
        // Delete the row from the data source
        Task *task = (Task*) [self.tasks objectAtIndex:indexPath.row];
        NSLog(@"task %@",task.id);
        [self deleteTask:task];
      //  [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

    }
    [self reloadTasks];
    [self.tasksTableView reloadData];
  
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    Task *task =(Task*) self.tasks[indexPath.row];
    TaskCell *taskCell = (TaskCell*)[tableView cellForRowAtIndexPath:indexPath];
    [self updateTask:task isDone:taskCell.isDone isAlert:task.isAlert];
    [self reloadTasks];
    [self.tasksTableView reloadData];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    NSString *stringToMove = [self.tasks objectAtIndex:sourceIndexPath.row];
    Task *oldTask = (Task*)[self.tasks objectAtIndex:sourceIndexPath.row];
    Task *newTask = (Task*)[self.tasks objectAtIndex:destinationIndexPath.row];
    [self moveTask:oldTask newTask:newTask];
    [self reloadTasks];
    [self.tasksTableView reloadData];
}


-(void)moveTask:(Task *)oldTask newTask:(Task*)newTask{
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];


    Task *oldTemp = oldTask;
    Task *newTemp = newTask;
    
    Task *updateOldTask = [self preparedTask:newTemp replaceTask:oldTask];
    Task *updateNewTask  =  [self preparedTask:oldTemp replaceTask:newTask];;
    
    [realm addOrUpdateObject:updateOldTask];
    [realm addOrUpdateObject:updateNewTask];
    [realm commitWriteTransaction];
    
}

-(Task*)preparedTask:(Task *)moveTask replaceTask:(Task*)replaceTask{
    replaceTask.note = moveTask.note;
    replaceTask.isDone = moveTask.isDone;
    replaceTask.isAlert = moveTask.isAlert;
    replaceTask.createdFor = moveTask.createdFor;
    replaceTask.createdAt = moveTask.createdAt;
    
    return replaceTask;
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
    [self transitionMode];
}

#pragma mark - JTCalendarDataSource

- (BOOL)calendarHaveEvent:(JTCalendar *)calendar date:(NSDate *)date
{
    if ([self reloadTasksByDate:date]) {
        return YES;
    }
    NSLog(@"have");
    
    return NO;
}

- (void)calendarDidDateSelected:(JTCalendar *)calendar date:(NSDate *)date
{
    NSLog(@"========select==========");
    if(!self.calendar.calendarAppearance.isWeekMode) {
        self.calendar.calendarAppearance.isWeekMode = true;
        [self transitionMode];
    }
    self.tasks = nil;
    [self reloadTasks];
    [self.tasksTableView reloadData];
}

- (void)calendarDidLoadPreviousPage
{
    [self.tasksTableView reloadData];
    NSLog(@"Previous page loaded");
}

- (void)calendarDidLoadNextPage
{
        [self.tasksTableView reloadData];
    NSLog(@"Next page loaded");
}

#pragma mark - Transition examples

- (void)transitionMode
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



@end
