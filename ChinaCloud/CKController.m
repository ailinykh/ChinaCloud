//
//  CKController.m
//  ChinaCloud
//
//  Created by tony on 10/10/16.
//  Copyright © 2016 Anthony Ilinykh. All rights reserved.
//

#import "CKController.h"

@implementation CKController

+ (instancetype)sharedController {
    static CKController *instance;
    static dispatch_once_t token;
    
    if (instance == nil) {
        dispatch_once(&token, ^{
            instance = [[CKController alloc] init];
        });
    }
    
    return instance;
}

@end
