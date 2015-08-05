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
#import <ObjectiveSugar/ObjectiveSugar.h>

static NSString * const kEDLHome = @"To Do List";

@interface ToDoViewController()<UITableViewDataSource,UITableViewDelegate,JTCalendarDataSource>

@property (strong, nonatomic) IBOutlet UIButton *changeModeButton;
@property (strong, nonatomic) IBOutlet UITableView *tasksTableView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet JTCalendarMenuView *weeMenuView;
@property (strong, nonatomic) RLMArray *tasks;
@property (weak, nonatomic) UITextView *todoTextView;
@property (strong, nonatomic) IBOutlet JTCalendarContentView *calendarContentView;
@property (strong, nonatomic) JTCalendar *calendar;
@property (strong,nonatomic) Task *selectedTask;
@property (nonatomic, strong) RLMNotificationToken *notification;
@property (assign) CGFloat screenWidth;
@property (assign) CGFloat screenHeight;

@end


@implementation ToDoViewController

NSMutableDictionary *eventsByDate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = kEDLHome;
    
    self.screenWidth = [UIScreen mainScreen].bounds.size.width;
    self.screenHeight = [UIScreen mainScreen].bounds.size.height;
    self.view.backgroundColor = [UIColor colorWithRed: 52.0/255.0f green:152.0/255.0f blue:220.0/255.0f alpha:1.0];
    
    self.changeModeButton.tintColor = [UIColor colorWithRed: 52.0/255.0f green:152.0/255.0f blue:220.0/255.0f alpha:1.0];
    self.changeModeButton.titleLabel.text = @"Chage Calendar View";
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
   
    __weak typeof(self) weakSelf = self;
    self.notification = [RLMRealm.defaultRealm addNotificationBlock:^(NSString *note, RLMRealm *realm) {
        [weakSelf loadTasks];
    }];

    [self loadBFPaperbutton];
    [self loadCalendarView];
    [self loadToayButton];
    [self loadTasks];
    [self setTableViewSetting];
    [self.tasksTableView reloadData];
    [self addConstraints];
    
}

-(void)viewWillAppear:(BOOL)animated{
    
    [self loadTasks];
    self.tasksTableView.rowHeight = UITableViewAutomaticDimension;
    [self.tasksTableView reloadData];
    
}

-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    
    [self transitionMode];
    [self.tasksTableView becomeFirstResponder];
    
}

-(void) setTableViewSetting{
    
    self.tasksTableView.backgroundColor = [UIColor clearColor];
    self.tasksTableView.dataSource = self;
    self.tasksTableView.delegate = self;
    
    self.tasksTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tasksTableView.allowsMultipleSelectionDuringEditing = NO;

}

-(void) loadCalendarView{
    
    self.calendar = [JTCalendar new];
    [self.calendar.calendarAppearance.calendar setTimeZone:[NSTimeZone systemTimeZone]];
    
    // All modifications on calendarAppearance to be done before setMenuMonthsView and setContentView
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
    
}

-(void) loadBFPaperbutton{
    
    //add Note Button position
    CGFloat xposition= self.screenWidth/2;
    CGFloat yposition= self.screenHeight-90;

    BFPaperButton *addNoteButton = [[BFPaperButton alloc] initWithFrame:CGRectMake(xposition-35, yposition, 70, 70) raised:YES];
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
    
}

-(void) loadToayButton{
    
    UIBarButtonItem *todayButton = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStylePlain target:self action:@selector(todayButtonPressed:)];
    todayButton.image= [UIImage imageNamed:@"Today Filled-25"];
    self.navigationItem.leftBarButtonItem = todayButton;
}

- (void)loadTasks{
    
    int daysToAdd = 1;
    NSDate *curretDate = [self gmtDate:[NSDate date]];
   // NSDate *newDate1 = [curretDate dateByAddingDays:daysToAdd];
    NSString *stringForPredicate = @"(createdFor ==  %@)";
    NSPredicate* filterPredicate = [NSPredicate predicateWithFormat:stringForPredicate,curretDate];
    self.tasks = [[Task objectsWithPredicate:filterPredicate] sortedResultsUsingProperty:@"sortId" ascending:YES];
    
    NSLog(@"order %lu",(unsigned long)self.tasks.count);

}

- (void)reloadTasks{
    int daysToAdd = 1;
    NSDate *newDate1 = [self gmtDate:self.calendar.currentDateSelected];
    NSString *stringForPredicate = @"(createdFor ==  %@)";
    NSPredicate* filterPredicate = [NSPredicate predicateWithFormat:stringForPredicate,newDate1];
    self.tasks = [[Task objectsWithPredicate:filterPredicate] sortedResultsUsingProperty:@"sortId" ascending:YES];
    NSLog(@"order %@",self.tasks);
}

- (BOOL*)reloadTasksByDate:(NSDate*)selectedDate{
    int daysToAdd = 1;
    NSDate *newDate1 = [self gmtDate:selectedDate];
    NSString *stringForPredicate = @"(createdFor ==  %@)";
    NSPredicate* filterPredicate = [NSPredicate predicateWithFormat:stringForPredicate, newDate1];
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
    if (tasks.count  >= 1) {
        NSMutableArray *idArray = [[NSMutableArray alloc] init];
        for (Task *task in tasks) {
            NSNumber *anumber = [NSNumber numberWithInteger:[task.id integerValue]];
            [idArray addObject:anumber];
        }
        
        NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
        [idArray sortUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];

        NSInteger *lastId =[[idArray firstObject] integerValue];
        task.id =  [NSString stringWithFormat:@"%i",(int)lastId + 1];
        task.sortId = (int)lastId + 1;
        
    }else{
        task.id = @"1";
        task.sortId =1;
    }

    
    task.note = note;
    task.createdAt =[self gmtDate:[NSDate date]];
    task.createdFor = [self gmtDate:createdFor];
    task.isDone = false;
    task.isAlert = false;
    [realm addObject:task];
    [realm commitWriteTransaction];
    [self reloadTasks];
    [self.tasksTableView reloadData];
    [self.calendar reloadAppearance];
    [self.calendar reloadData];

}

-(NSDate *)gmtDate:(NSDate*)date
{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd"; // drops the seconds
    
    dateFormatter.timeZone = [NSTimeZone systemTimeZone]; // the local TZ
    NSString *localTimeStamp = [dateFormatter stringFromDate:date];
    // localTimeStamp is the current clock time in the current TZ
    
    // adjust date so it'll be the same clock time in GMT
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSDate *gmtDate = [dateFormatter dateFromString:localTimeStamp];
    return gmtDate;
}


-(void)updateTask:(Task *)task isDone:(BOOL*)isDone isAlert:(BOOL*)isAlert{

    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    task.isDone = isDone;
    task.isAlert = isAlert;
    Task *updateTask = [Task createOrUpdateInDefaultRealmWithObject:task];
    [realm addOrUpdateObject:updateTask];
    [realm commitWriteTransaction];

}



-(void)deleteTask:(Task *)task{
    RLMRealm *realm = RLMRealm.defaultRealm;
    // Updating book with id = 1
    [realm beginWriteTransaction];
    [realm deleteObject:task];
    [realm commitWriteTransaction];
    [self reloadTasks];
    [self.tasksTableView reloadData];
    [self.calendar reloadAppearance];
    [self.calendar reloadData];

}



- (IBAction)pressedaddNoteButton:(id)sender {
    int daysToAdd = 1;
    NSDate *newDate1 = [self.calendar.currentDateSelected dateByAddingTimeInterval:60*60*24*daysToAdd];
    NSString *stringForPredicate = @"(createdFor >=  %@) and (createdFor < %@)";
    NSPredicate* filterPredicate = [NSPredicate predicateWithFormat:stringForPredicate, self.calendar.currentDateSelected,newDate1];
    NSArray *tasksInDay = [[Task objectsWithPredicate:filterPredicate] sortedResultsUsingProperty:@"id" ascending:YES];
    if (tasksInDay.count != 0) {
        if ((tasksInDay.count%5) == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Productivity Alert!!!"
                                                            message:@"You have many tasks to do. Is that important priority this day?"
                                                           delegate:self
                                                  cancelButtonTitle:@"NO"
                                                  otherButtonTitles:@"YES",nil];
            [alert show];
        }else{
            [self addTaskForm];
        }
    }else{
        [self addTaskForm];
    }
   
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"Cancel Tapped.");
    }
    else if (buttonIndex == 1) {
      [self addTaskForm];
    }
}

-(void) addTaskForm{
    
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
//    self.tasks =nil;
    [self loadTasks];
    [self.tasksTableView reloadData];
    [self.calendar reloadData];
    [self.calendar reloadAppearance];
    
}

- (void)pressedDoneButton:(UIBarButtonItem *)sender
{
    Task *task = [self.tasks objectAtIndex:sender.tag];
    bool flag = task.isDone ? false : true;
    [self updateTask:task isDone:flag isAlert:task.isAlert];
    [self reloadTasks];
    [self.tasksTableView reloadData];
    
    
}


-(void)timeWasSelected:(NSDate *)selectedTime{


       if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound|UIUserNotificationTypeBadge
                                                                                                              categories:nil]];
           // create a local notification
           UILocalNotification *notification = [[UILocalNotification alloc]init];
           NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
           NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:self.selectedTask.createdFor];
           
           [calendar setTimeZone:[NSTimeZone systemTimeZone]];
           [components setHour:[selectedTime hour]];
           [components setMinute:[selectedTime minute]];
           NSDate *notiDatetime = [calendar dateFromComponents:components];
           if(notiDatetime.timeIntervalSinceNow <0){
               SCLAlertView *alert = [[SCLAlertView alloc] init];
               alert.customViewColor =[UIColor colorWithRed: 52.0/255.0f green:152.0/255.0f blue:220.0/255.0f alpha:1.0];
               [alert showError:self title:@"Error" subTitle:@"Reminder Time is Ealier Than Current Time." closeButtonTitle:@"OK" duration:0.0f]; // Error
           }
           else{
               
               notification.fireDate = notiDatetime;
               notification.timeZone = [NSTimeZone systemTimeZone];
               notification.soundName = UILocalNotificationDefaultSoundName;
               notification.alertAction = @"Ok";
               notification.alertBody =self.selectedTask.note;
               [[UIApplication sharedApplication]scheduleLocalNotification:notification];
               [self updateTask:self.selectedTask isDone:false isAlert:true];
               [self reloadTasks];
               [self.tasksTableView reloadData];
               [self.calendar reloadAppearance];

           }
          
    }
    
  
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
    
    if (task.isDone == TRUE) {
        NSDictionary* attributes = @{
                                     
                                     NSStrikethroughStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleSingle]
                                     
                                     };
        
        
        
        NSAttributedString* attrText = [[NSAttributedString alloc] initWithString:task.note attributes:attributes];
        taskCell.taskName.attributedText = attrText;
    }
    else{
         taskCell.taskName.text = task.note;
    }
   
    [taskCell.taskName sizeToFit];
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
    
    return 70;
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
       
        [self deleteTask:task];
      //  [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

    }
    [self reloadTasks];
    [self.tasksTableView reloadData];
  
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    Task *task =(Task*) self.tasks[indexPath.row];
    [self updateTask:task isDone:true isAlert:task.isAlert];
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
    int  replaceSortId= newTask.sortId;
    int  moveSortId= oldTask.sortId;
    [realm beginWriteTransaction];

    oldTask.sortId = replaceSortId;
    newTask.sortId = moveSortId;
    [realm commitWriteTransaction];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (IBAction)didGoTodayTouch
{
    [self.calendar setCurrentDateSelected:[NSDate date]];
    [self.calendar setCurrentDate:[NSDate date]];
    self.tasks = nil;
    [self reloadTasks];
    [self.tasksTableView reloadData];
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

}

- (void)calendarDidLoadNextPage
{
    [self.tasksTableView reloadData];

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


- (void) addConstraints{
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.changeModeButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:0 constant:self.screenWidth]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tasksTableView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:0 constant:self.screenWidth]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarContentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:0 constant:self.screenWidth]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.weeMenuView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:0 constant:self.screenWidth]];
    
    if(self.screenHeight > 600){
        
        NSLog(@"self.view.height %f",self.screenHeight);
        CGFloat screenheight = self.screenHeight-250;
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tasksTableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:0 constant:screenheight]];
    }
    
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:self.weeMenuView
                              attribute:NSLayoutAttributeCenterX
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.view
                              attribute:NSLayoutAttributeCenterX
                              multiplier:1.0
                              constant:0.0]];
    
    [self.view layoutIfNeeded];
    [self.calendar repositionViews];
    
}

@end
