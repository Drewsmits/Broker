//
//  EmployeeTableViewController.m
//  BrokerTestApp
//
//  Created by Andrew Smith on 11/7/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "EmployeeTableViewController.h"

// Frameworks
#import <Broker/BrokerHeaders.h>

// Controllers
#import "BKTestAppDelegate.h"
#import "BKTestAppStore.h"
#import "BrokerTestsHelpers.h"

@interface EmployeeTableViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) IBOutlet UIButton *createButton;

@property (nonatomic, strong) Broker *broker;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

- (IBAction)createEmployees:(id)sender;

- (IBAction)resetStore:(id)sender;

@end

@implementation EmployeeTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //
    // Ya know, broker
    //
    self.broker = [Broker broker];
    
    NSManagedObjectContext *context = [[[BKTestAppDelegate sharedInstance] store] managedObjectContext];
    
    //
    // Register
    //
    [self.broker.entityMap registerEntityNamed:@"Employee"
                                withPrimaryKey:@"employeeID"
                       andMapNetworkProperties:nil
                             toLocalProperties:nil
                                     inContext:context];

    //
    // Setup fetched results controller
    //
    [self buildFetchController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[[BKTestAppDelegate sharedInstance] store] reset:nil];
}

#pragma mark - Broker

- (IBAction)createEmployees:(id)sender
{
    self.createButton.enabled = NO;
    
    NSManagedObjectContext *mainContext = [[[BKTestAppDelegate sharedInstance] store] managedObjectContext];
    
    id json = JsonFromFile(@"department_employees_10000.json");

    [self.broker processJSONCollection:json
                       asEntitiesNamed:@"Employee"
                             inContext:mainContext
                       completionBlock:^{
                           //
                           // Optionally you can persist the data to the store
                           //
                           [mainContext performBlock:^{
                               [mainContext save:nil];
                           }];
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               self.createButton.enabled = YES; 
                           });
                       }];
}

- (IBAction)resetStore:(id)sender
{
    [[[BKTestAppDelegate sharedInstance] store] reset:nil];
    [self buildFetchController];
    [self.tableView reloadData];
}

#pragma mark - 

- (void)buildFetchController
{
    NSManagedObjectContext *context = [[[BKTestAppDelegate sharedInstance] store] managedObjectContext];
    
    //
    // Setup fetched results controller
    //
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"employeeID" ascending:YES]];
    
    NSFetchedResultsController *tempController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                     managedObjectContext:context
                                                                                       sectionNameKeyPath:nil
                                                                                                cacheName:nil];
    
    tempController.delegate = self;
    self.fetchedResultsController = tempController;
    [self.fetchedResultsController performFetch:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"EmployeeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (UITableViewCell *)configureCell:(UITableViewCell *)cell
                       atIndexPath:(NSIndexPath *)path
{
    NSManagedObject *employee =  [self.fetchedResultsController objectAtIndexPath:path];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@, %@", [employee valueForKey:@"firstname"], [employee valueForKey:@"lastname"]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"ID: %@", [employee valueForKey:@"employeeID"]];
    
    return cell;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
    
    // Update sections
    for (NSInteger i = self.tableView.numberOfSections; i < controller.sections.count; i++) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:i]
                      withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath]
                    atIndexPath:indexPath];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeUpdate:
            break;
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end
