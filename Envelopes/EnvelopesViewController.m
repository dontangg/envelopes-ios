//
//  MasterViewController.m
//  Envelopes
//
//  Created by Don Wilson on 11/9/13.
//  Copyright (c) 2013 Don Wilson. All rights reserved.
//

#import "EnvelopesViewController.h"

#import "TransactionsViewController.h"

@interface EnvelopesViewController ()
    @property (nonatomic, strong) NSDictionary *envelopes;
@end

@implementation EnvelopesViewController

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

    _envelopes = nil;
    [self getEnvelopes];
}

- (void)getEnvelopes
{
    NSURL *url = [NSURL URLWithString:@"http://money.thewilsonpad.com/envelopes.json?api_token=d108svjwx9"];
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDownloadTask *downloadTask = [urlSession downloadTaskWithURL:url
                                                           completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                               if (error)
                                                                   NSLog(@"error downloading file: %@", error);

                                                               NSURL *folderUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];

                                                               folderUrl = [folderUrl URLByAppendingPathComponent:@"downloads" isDirectory:YES];
                                                               [[NSFileManager defaultManager] createDirectoryAtURL:folderUrl withIntermediateDirectories:YES attributes:nil error:&error];
                                                               if (error)
                                                                   NSLog(@"error creating directory: %@", error);

                                                               NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                                               [dateFormatter setDateFormat:@"yyyy-MM-dd"];
                                                               NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];

                                                               NSString *filename = [NSString stringWithFormat:@"envelopes-%@", dateString];

                                                               NSLog(@"filename: %@", filename);

                                                               NSURL *fileUrl = [folderUrl URLByAppendingPathComponent:filename]; // The url is now "<App Sandbox>/<Documents Directory>/downloads/<filename>"

                                                               NSArray *existingFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:folderUrl includingPropertiesForKeys:nil options:kNilOptions error:&error];
                                                               if (error)
                                                                   NSLog(@"error listing files in %@: %@", folderUrl, error);

                                                               for (NSURL *existingFileUrl in existingFiles) {
                                                                   [[NSFileManager defaultManager] removeItemAtURL:existingFileUrl error:&error];

                                                                   if (error)
                                                                       NSLog(@"error deleting file %@: %@", existingFileUrl, error);
                                                               }

                                                               [[NSFileManager defaultManager] moveItemAtURL:location toURL:fileUrl error:&error];
                                                               if (error)
                                                                   NSLog(@"error moving file: %@", error);

                                                               NSData *envelopesData = [NSData dataWithContentsOfURL:fileUrl];

                                                               NSDictionary *envelopes = [NSJSONSerialization JSONObjectWithData:envelopesData options:kNilOptions error:&error];
                                                               if (error)
                                                                   NSLog(@"error deserializing json: %@", error);

                                                               self.envelopes = envelopes;
                                                               NSLog(@"%@", envelopes);

                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   [self.tableView reloadData];
                                                               });
                                                           }];
    [downloadTask resume];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (!self.envelopes || !self.envelopes[@""])
        return 0;

    NSArray *topLevelEnvelopes = self.envelopes[@""];
    return topLevelEnvelopes.count;
}

- (NSDictionary *)envelopeForSection:(NSInteger)section
{
    NSArray *topLevelEnvelopes = self.envelopes[@""];
    return topLevelEnvelopes[section];
}

- (NSArray *)subEnvelopesForSection:(NSInteger)section
{
    NSDictionary *topLevelEnvelope = [self envelopeForSection:section];

    NSNumber *topLevelEnvelopeId = topLevelEnvelope[@"id"];

    return self.envelopes[[topLevelEnvelopeId stringValue]];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSDictionary *envelope = [self envelopeForRowAtIndexPath:indexPath];

    cell.textLabel.text = envelope[@"name"];
    cell.detailTextLabel.text = envelope[@"total_amount"];

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
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDictionary *envelope = [self envelopeForRowAtIndexPath:indexPath];
        [[segue destinationViewController] setDetailItem:envelope];
    }
}

- (IBAction)refreshPressed:(UIBarButtonItem *)sender {
    [self getEnvelopes];
}
@end
