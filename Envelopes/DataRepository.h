//
//  DataRepository.h
//  Envelopes
//
//  Created by Don Wilson on 3/7/14.
//  Copyright (c) 2014 Don Wilson. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DataCallback)(NSArray *items, NSString *errorMessage);

@interface DataRepository : NSObject

+ (void)getEnvelopesUsingToken:(NSString *)token allowCache:(BOOL)allowCache callback:(DataCallback)callback;
+ (void)getTransactionsInEnvelope:(long)envelopeId usingToken:(NSString *)token callback:(DataCallback)callback;

@end
