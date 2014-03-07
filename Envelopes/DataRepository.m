//
//  DataRepository.m
//  Envelopes
//
//  Created by Don Wilson on 3/7/14.
//  Copyright (c) 2014 Don Wilson. All rights reserved.
//

#import "DataRepository.h"

@implementation DataRepository

+ (void)getEnvelopesUsingToken:(NSString *)token allowCache:(BOOL)allowCache callback:(EnvelopesCallback)callback
{
    // Get the downloads folder
    NSURL *folderUrl = [self getDownloadsFolderUrl];
    NSURL *fileUrl = [self getEnvelopesFileUrl:folderUrl];

    if (allowCache && [[NSFileManager defaultManager] fileExistsAtPath:[fileUrl path]]) {
        NSLog(@"Reading file from cache");
        [self readEnvelopesFile:fileUrl andCallback:callback];
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://money.thewilsonpad.com/envelopes.json?api_token=%@", token]];

    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDownloadTask *downloadTask = [urlSession downloadTaskWithURL:url
                                                           completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                               if (error)
                                                                   NSLog(@"error downloading file: %@", error);

                                                               [self deleteCachedFiles:folderUrl];

                                                               // Move the recently downloaded file to the downloads folder and give it the new file name
                                                               [[NSFileManager defaultManager] moveItemAtURL:location toURL:fileUrl error:&error];
                                                               if (error)
                                                                   NSLog(@"error moving file: %@", error);

                                                               [self readEnvelopesFile:fileUrl andCallback:callback];
                                                           }];
    [downloadTask resume];
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

+ (void)readEnvelopesFile:(NSURL *)fileUrl andCallback:(EnvelopesCallback)callback
{
    // Read the data from the downloaded file
    NSData *envelopesData = [NSData dataWithContentsOfURL:fileUrl];

    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:envelopesData options:kNilOptions error:&error];
    if (error)
        NSLog(@"error deserializing json: %@", error);

    NSArray *envelopes = [self organizeEnvelopes:json];

    NSLog(@"%@", envelopes);

    dispatch_async(dispatch_get_main_queue(), ^{
        callback(envelopes);
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
