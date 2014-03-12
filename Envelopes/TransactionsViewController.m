//
//  DetailViewController.m
//  Envelopes
//
//  Created by Don Wilson on 11/9/13.
//  Copyright (c) 2013 Don Wilson. All rights reserved.
//

#import "TransactionsViewController.h"
#import "DataRepository.h"

@interface TransactionsViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@property (nonatomic, strong) NSArray *transactions;
@end

@implementation TransactionsViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
        self.navigationItem.title = self.detailItem[@"name"];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];

    long envelopeId = [(NSNumber *)self.detailItem[@"id"] longValue];
    NSString *token = [[NSUserDefaults standardUserDefaults] stringForKey:@"ApiToken"];
    [DataRepository getTransactionsInEnvelope:envelopeId usingToken:token callback:^(NSArray *transactions, NSString *errorMessage) {
        self.transactions = transactions;
        [self.tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Envelopes", nil);
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.transactions ? self.transactions.count : 0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Envelope Details";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSDictionary *transaction = [self envelopeForRowAtIndexPath:indexPath];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"transaction" forIndexPath:indexPath];

    NSDictionary *transaction = self.transactions[indexPath.row];

    UILabel *label;

    // Populate the payee
    label = (UILabel *)[cell viewWithTag:1];
    label.text = transaction[@"payee"];

    // Format the "posted at" date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *date = [dateFormatter dateFromString:transaction[@"posted_at"]];
    [dateFormatter setDateFormat:@"E, MMMM d, y"];

    // Populate the date
    label = (UILabel *)[cell viewWithTag:2];
    label.text = [dateFormatter stringFromDate:date];

    // Format the amount
    float totalAmount = [transaction[@"amount"] floatValue];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];

    // Populate the amount
    label = (UILabel *)[cell viewWithTag:3];
    label.text = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:totalAmount]];
    label.textColor = totalAmount > 0 ? [UIColor colorWithRed:0 green:0.4 blue:0 alpha:1] : [UIColor lightGrayColor];

    return cell;
}

@end
