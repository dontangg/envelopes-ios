//
//  DataRepository.h
//  Envelopes
//
//  Created by Don Wilson on 3/7/14.
//  Copyright (c) 2014 Don Wilson. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^EnvelopesCallback)(NSArray *);

@interface DataRepository : NSObject

+ (void)getEnvelopesUsingToken:(NSString *)token allowCache:(BOOL)allowCache callback:(EnvelopesCallback)callback;

@end
