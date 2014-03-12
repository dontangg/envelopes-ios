//
//  DataRepository.m
//  Envelopes
//
//  Created by Don Wilson on 3/7/14.
//  Copyright (c) 2014 Don Wilson. All rights reserved.
//

#import "DataRepository.h"

@implementation DataRepository

+ (void)getTransactionsInEnvelope:(long)envelopeId usingToken:(NSString *)token callback:(DataCallback)callback
{
    NSURL *folderUrl = [self getDownloadsFolderUrl];
    __block NSURL *fileUrl = [self getTransactionsFileUrl:folderUrl forEnvelope:envelopeId];

    if ([[NSFileManager defaultManager] fileExistsAtPath:[fileUrl path]]) {
        NSLog(@"Reading transactions file from cache");
        [self readTransactionsFile:fileUrl andCallback:callback];
        return;
    }

    NSLog(@"%@", [NSString stringWithFormat:@"http://money.thewilsonpad.com/envelopes/%ld/transactions.json?api_token=%@", envelopeId, token]);
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://money.thewilsonpad.com/envelopes/%ld/transactions.json?api_token=%@", envelopeId, token]];

    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDownloadTask *downloadTask = [urlSession downloadTaskWithURL:url
                                                           completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                               if (error) {
                                                                   NSLog(@"error downloading file: %@", error);
                                                                   [self invokeCallback:callback data:nil errorMessage:@"Error downloading the transactions file"];
                                                                   return;
                                                               }

                                                               // Move the recently downloaded file to the downloads folder and give it the new file name
                                                               [[NSFileManager defaultManager] moveItemAtURL:location toURL:fileUrl error:&error];
                                                               if (error) {
                                                                   NSLog(@"error moving file: %@", error);

                                                                   // If we couldn't move the file, just read it at it's current location
                                                                   fileUrl = location;
                                                               }

                                                               [self readTransactionsFile:fileUrl andCallback:callback];
                                                           }];
    [downloadTask resume];
}

+ (void)getEnvelopesUsingToken:(NSString *)token allowCache:(BOOL)allowCache callback:(DataCallback)callback
{
    // Get the downloads folder
    NSURL *folderUrl = [self getDownloadsFolderUrl];
    __block NSURL *fileUrl = [self getEnvelopesFileUrl:folderUrl];

    if (allowCache && [[NSFileManager defaultManager] fileExistsAtPath:[fileUrl path]]) {
        NSLog(@"Reading file from cache");
        [self readEnvelopesFile:fileUrl andCallback:callback];
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://money.thewilsonpad.com/envelopes.json?api_token=%@", token]];

    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDownloadTask *downloadTask = [urlSession downloadTaskWithURL:url
                                                           completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                               if (error) {
                                                                   NSLog(@"error downloading file: %@", error);
                                                                   [self invokeCallback:callback data:nil errorMessage:@"Error downloading the envelopes file"];
                                                                   return;
                                                               }

                                                               [self deleteCachedFiles:folderUrl];

                                                               // Move the recently downloaded file to the downloads folder and give it the new file name
                                                               [[NSFileManager defaultManager] moveItemAtURL:location toURL:fileUrl error:&error];
                                                               if (error) {
                                                                   NSLog(@"error moving file: %@", error);

                                                                   // If we couldn't move the file, just read it at it's current location
                                                                   fileUrl = location;
                                                               }

                                                               [self readEnvelopesFile:fileUrl andCallback:callback];
                                                           }];
    [downloadTask resume];
}

+ (NSURL *)getTransactionsFileUrl:(NSURL *)folderUrl forEnvelope:(long)envelopeId
{
    // Create a file name with the date in it eg. transactions-3-2014-02-14
    NSString *dateString = [self getTodayDateString];
    NSString *filename = [NSString stringWithFormat:@"transactions-%ld-%@", envelopeId, dateString];

    NSLog(@"filename: %@", filename);

    // The url will be "<App Sandbox>/<Documents Directory>/downloads/<filename>"
    return [folderUrl URLByAppendingPathComponent:filename];
}

+ (NSURL *)getEnvelopesFileUrl:(NSURL *)folderUrl
{
    // Create a file name with the date in it eg. envelopes-2014-02-14
    NSString *dateString = [self getTodayDateString];
    NSString *filename = [NSString stringWithFormat:@"envelopes-%@", dateString];

    NSLog(@"filename: %@", filename);

    // The url will be "<App Sandbox>/<Documents Directory>/downloads/<filename>"
    return [folderUrl URLByAppendingPathComponent:filename];
}

+ (void)readTransactionsFile:(NSURL *)fileUrl andCallback:(DataCallback)callback
{
    // Read the data from the downloaded file
    NSData *transactionsData = [NSData dataWithContentsOfURL:fileUrl];

    NSError *error;
    NSArray *json = [NSJSONSerialization JSONObjectWithData:transactionsData options:kNilOptions error:&error];
    if (error) {
        NSLog(@"error deserializing transactions json: %@", error);
        [self invokeCallback:callback data:nil errorMessage:@"Error deserializing transactions json response"];
        return;
    }

    NSArray *transactions = json;

    NSLog(@"%@", transactions);

    [self invokeCallback:callback data:transactions errorMessage:nil];
}

+ (void)readEnvelopesFile:(NSURL *)fileUrl andCallback:(DataCallback)callback
{
    // Read the data from the downloaded file
    NSData *envelopesData = [NSData dataWithContentsOfURL:fileUrl];

    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:envelopesData options:kNilOptions error:&error];
    if (error) {
        NSLog(@"error deserializing json: %@", error);
        [self invokeCallback:callback data:nil errorMessage:@"Error deserializing json response"];
        return;
    }

    NSArray *envelopes = [self organizeEnvelopes:json];

    NSLog(@"%@", envelopes);

    [self invokeCallback:callback data:envelopes errorMessage:nil];
}

+ (void)invokeCallback:(DataCallback)callback data:(NSArray *)data errorMessage:(NSString *)errorMessage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        callback(data, errorMessage);
    });
}

+ (void)deleteCachedFiles:(NSURL *)folderUrl
{
    // Get a list of files in the directory and delete them all
    NSError *error;
    NSArray *existingFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:folderUrl includingPropertiesForKeys:nil options:kNilOptions error:&error];
    if (error)
        NSLog(@"error listing files in %@: %@", folderUrl, error);

    for (NSURL *existingFileUrl in existingFiles) {
        [[NSFileManager defaultManager] removeItemAtURL:existingFileUrl error:&error];

        if (error)
            NSLog(@"error deleting file %@: %@", existingFileUrl, error);
    }
}

+ (NSString *)getTodayDateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    return [dateFormatter stringFromDate:[NSDate date]];
}

+ (NSURL *)getDownloadsFolderUrl
{
    NSURL *folderUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];

    folderUrl = [folderUrl URLByAppendingPathComponent:@"downloads" isDirectory:YES];

    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtURL:folderUrl withIntermediateDirectories:YES attributes:nil error:&error];
    if (error)
        NSLog(@"error creating directory: %@", error);

    return folderUrl;
}

+ (NSArray *)organizeEnvelopes:(NSDictionary *)json
{
    NSInteger topLevelEnvelopeCount = ([json[@""] count] + 1);
    NSMutableArray *envelopes = [NSMutableArray arrayWithCapacity:topLevelEnvelopeCount];

    // Do the system envelopes (all, available, pending, unassigned)
    NSMutableDictionary *sysEnvelope = [NSMutableDictionary dictionaryWithObject:@"System" forKey:@"name"];
    NSMutableArray *sysChildEnvelopes = [NSMutableArray arrayWithCapacity:[json[@"sys"] count]];
    for (NSDictionary *sysJsonChildEnvelope in json[@"sys"]) {
        NSMutableDictionary *sysChildEnvelope = [sysJsonChildEnvelope mutableCopy];
        [sysChildEnvelopes addObject:sysChildEnvelope];
    }
    sysEnvelope[@"children"] = sysChildEnvelopes;
    [envelopes addObject:sysEnvelope];

    // Now we'll add all the rest of the envelopes
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
