//
//  CKSmartConnectionController.h
//  ChinaCloud
//
//  Created by tony on 10/10/16.
//  Copyright © 2016 Anthony Ilinykh. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CCSmartConnectionDelegate;

@interface CCSmartConnectionController : NSObject

- (instancetype)initWithSSID:(NSString*)ssid
                 andPassword:(NSString*)password;

- (void)startSmartConnection;
- (void)stopSmartConnection;

@property (nonatomic, assign) id<CCSmartConnectionDelegate> delegate;

@end


@protocol CCSmartConnectionDelegate <NSObject>

- (void)smartConnectionDidStart;
- (void)smartConnectionDidStop;
- (void)smartConnectionDidFail:(NSError*)error;
- (void)smartConnectionDidReceiveDeviceId:(NSString*)deviceId;

@end
