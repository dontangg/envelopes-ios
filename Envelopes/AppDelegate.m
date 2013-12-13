//
//  AppDelegate.m
//  Envelopes
//
//  Created by Don Wilson on 11/9/13.
//  Copyright (c) 2013 Don Wilson. All rights reserved.
//

#import "AppDelegate.h"
#import "EnvelopesViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
    }

    [self getEnvelopes];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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

                                                               NSDictionary *json = [NSJSONSerialization JSONObjectWithData:envelopesData options:kNilOptions error:&error];
                                                               if (error)
                                                                   NSLog(@"error deserializing json: %@", error);

                                                               NSArray *envelopes = [self organizeEnvelopes:json];

                                                               NSLog(@"%@", envelopes);
                                                               
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                                                                       UINavigationController *navController = (UINavigationController *)self.window.rootViewController;

                                                                       EnvelopesViewController *envelopesViewController = (EnvelopesViewController *)navController.viewControllers[0];
                                                                       envelopesViewController.envelopes = envelopes;
                                                                   }
                                                               });
                                                           }];
    [downloadTask resume];
}

- (NSArray *)organizeEnvelopes:(NSDictionary *)json {
    NSMutableArray *envelopes = [NSMutableArray arrayWithCapacity:[json[@""] count]];

    for (NSDictionary *jsonEnvelope in json[@""]) {
        NSMutableDictionary *envelope = [jsonEnvelope mutableCopy];
        [envelopes addObject:envelope];

        NSString *idStr = [envelope[@"id"] stringValue];

        if (json[idStr]) {
            NSMutableArray *l1Envelopes = [NSMutableArray arrayWithCapacity:[json[idStr] count]];
            for (NSDictionary *l1JsonEnvelope in json[idStr]) {
                NSMutableDictionary *l1Envelope = [l1JsonEnvelope mutableCopy];
                [l1Envelopes addObject:l1Envelope];

                idStr = [l1Envelope[@"id"] stringValue];

                if (json[idStr]) {
                    NSMutableArray *l2Envelopes = [NSMutableArray arrayWithCapacity:[json[idStr] count]];
                    for (NSDictionary *l2JsonEnvelope in json[idStr]) {
                        NSMutableDictionary *l2Envelope = [l2JsonEnvelope mutableCopy];
                        [l2Envelopes addObject:l2Envelope];
                    }

                    l1Envelope[@"children"] = l2Envelopes;
                }
            }

            envelope[@"children"] = l1Envelopes;
        }
    }

    return envelopes;
}

@end
