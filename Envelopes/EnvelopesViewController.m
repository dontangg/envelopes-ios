//
//  MasterViewController.m
//  Envelopes
//
//  Created by Don Wilson on 11/9/13.
//  Copyright (c) 2013 Don Wilson. All rights reserved.
//

#import "EnvelopesViewController.h"
#import "TransactionsViewController.h"
#import "DataRepository.h"

@interface EnvelopesViewController ()
    
@end

@implementation EnvelopesViewController

- (void)setEnvelopes:(NSArray *)envelopes {
    _envelopes = envelopes;
    [self.tableView reloadData];
}

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    self.detailViewController = (TransactionsViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];

    UIBarButtonItem *settingsButton = self.navigationItem.leftBarButtonItem;
    UIFont *customFont = [UIFont fontWithName:@"Helvetica Neue" size:26.0];
    NSDictionary *fontDictionary = @{NSFontAttributeName: customFont};
    [settingsButton setTitleTextAttributes:fontDictionary forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (!self.envelopes)
        return 0;

    return self.envelopes.count;
}

- (NSDictionary *)envelopeForSection:(NSInteger)section
{
    return self.envelopes[section];
}

- (NSArray *)subEnvelopesForSection:(NSInteger)section
{
    NSDictionary *topLevelEnvelope = [self envelopeForSection:section];

    return topLevelEnvelope[@"children"];
}

- (NSDictionary *)envelopeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *subEnvelopes = [self subEnvelopesForSection:indexPath.section];
    return subEnvelopes[indexPath.row];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *subEnvelopes = [self subEnvelopesForSection:section];

    return subEnvelopes.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *topLevelEnvelope = [self envelopeForSection:section];

    return topLevelEnvelope[@"name"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *envelope = [self envelopeForRowAtIndexPath:indexPath];

    // Figure out if we are displaying a parent envelope or an envelope with an amount
    NSString *cellIdentifier = envelope[@"children"] ? @"ParentEnvelopeCell" : @"CellWithAmount";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];


    cell.textLabel.text = envelope[@"name"];

    float totalAmount = [envelope[@"total_amount"] floatValue];

    if (!envelope[@"children"]) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        cell.detailTextLabel.text = [formatter stringFromNumber:[NSNumber numberWithFloat:totalAmount]];
    }

    cell.detailTextLabel.textColor = totalAmount < 0 ? [UIColor redColor] : [UIColor lightGrayColor];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

/*
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSDictionary *envelope = [self envelopeForRowAtIndexPath:indexPath];
        self.detailViewController.detailItem = envelope;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSDictionary *envelope = [self envelopeForRowAtIndexPath:indexPath];

    if ([segue.identifier isEqualToString:@"transactions"]) {
        [segue.destinationViewController setDetailItem:envelope];
    } else if ([segue.identifier isEqualToString:@"subenvelopes"]) {
        EnvelopesViewController *vc = segue.destinationViewController;
        vc.envelopes = @[envelope];
    }
}

- (IBAction)refreshPressed:(UIBarButtonItem *)sender {
    NSString *token = [[NSUserDefaults standardUserDefaults] stringForKey:@"APIToken"];
    if (!token || token.length == 0)
        return;
    
    [DataRepository getEnvelopesUsingToken:token allowCache:NO callback:^(NSArray *envelopes, NSString *errorMessage) {
        self.envelopes = envelopes;
    }];
}

@end
