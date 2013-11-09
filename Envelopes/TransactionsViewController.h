//
//  DetailViewController.h
//  Envelopes
//
//  Created by Don Wilson on 11/9/13.
//  Copyright (c) 2013 Don Wilson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TransactionsViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
