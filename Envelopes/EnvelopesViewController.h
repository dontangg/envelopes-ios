//
//  MasterViewController.h
//  Envelopes
//
//  Created by Don Wilson on 11/9/13.
//  Copyright (c) 2013 Don Wilson. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TransactionsViewController;

@interface EnvelopesViewController : UITableViewController

@property (strong, nonatomic) TransactionsViewController *detailViewController;
- (IBAction)refreshPressed:(UIBarButtonItem *)sender;

@end
