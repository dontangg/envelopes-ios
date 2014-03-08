//
//  SettingsViewController.h
//  Envelopes
//
//  Created by Don Wilson on 3/8/14.
//  Copyright (c) 2014 Don Wilson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *tokenField;

- (IBAction)donePressed:(UIBarButtonItem *)sender;

@end
