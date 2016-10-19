//
//  CCSmartConnectionController.m
//  ChinaCloud
//
//  Created by tony on 10/10/16.
//  Copyright © 2016 Anthony Ilinykh. All rights reserved.
//

#import "CCSmartConnectionController.h"
#import "GCDAsyncUdpSocket.h"
#import "elian.h"

NSErrorDomain const CCErrorDomain = @"ru.ailinykh.ChinaCloud";

@interface CCSmartConnectionController () {
    void *_context;
    int _attempts;
    GCDAsyncUdpSocket *_socket;
    NSString *_deviceId;
    NSString *_ssid;
    NSString *_password;
}

@end

@implementation CCSmartConnectionController

- (instancetype)initWithSSID:(NSString *)ssid andPassword:(NSString *)password {
    if (self = [super init]) {
        _ssid = ssid;
        _password = password;
        
        [self _initSmartConnection];
        [self _initSocketConnection];
    }
    return self;
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    elianDestroy(_context);
    if (_socket) {
        [_socket close];
    }
}

- (void)startSmartConnection
{
    if (_attempts++ < 3)
    {
        int result = elianStart(_context);
        NSLog(@"elian started with status: %d", result);
        [self performSelector:@selector(stopSmartConnection) withObject:nil afterDelay:20];
        if ([_delegate respondsToSelector:@selector(smartConnectionDidStart)]) {
            [_delegate smartConnectionDidStart];
        }
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(smartConnectionDidFail:)]) {
            NSError *err = [NSError errorWithDomain:CCErrorDomain code:500 userInfo:@{NSLocalizedDescriptionKey: @"Connection attempts reached"}];
            [_delegate smartConnectionDidFail:err];
        }
    }
}

- (void)stopSmartConnection
{
    [self stopSmartConnectionWithRepeatTimeout:NO];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)stopSmartConnectionWithRepeatTimeout:(BOOL)isRepeat {
    elianStop(_context);
    
    if ([_delegate respondsToSelector:@selector(smartConnectionDidStop)]) {
        [_delegate smartConnectionDidStop];
    }
    
    if (isRepeat) {
        [self performSelector:@selector(startSmartConnection) withObject:nil afterDelay:10];
    }
}

#pragma mark - private

- (void)_initSmartConnection
{
    if (!_context) {
        //ssid
        const char *ssid = [_ssid cStringUsingEncoding:NSUTF8StringEncoding];
        //authmode
        int authmode = 9;//delete
        //pwd
        const char *password = [_password cStringUsingEncoding:NSUTF8StringEncoding];//NSASCIIStringEncoding
        //target
        unsigned char target[] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
        
        
        _context = elianNew(NULL, 0, target, ELIAN_SEND_V1 | ELIAN_SEND_V4);
        elianPut(_context, TYPE_ID_AM, (char *)&authmode, 1);//delete
        elianPut(_context, TYPE_ID_SSID, (char *)ssid, strlen(ssid));
        elianPut(_context, TYPE_ID_PWD, (char *)password, strlen(password));
    }
}

- (void)_initSocketConnection
{
    _socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    NSError *error = nil;
    
    if (![_socket bindToPort:9988 error:&error])
    {
        NSLog(@"❌Error binding: %@", [error localizedDescription]);
    }
    if (![_socket beginReceiving:&error])
    {
        NSLog(@"❌Error receiving: %@", [error localizedDescription]);
    }
    if (![_socket enableBroadcast:YES error:&error])
    {
        NSLog(@"❌Error enableBroadcast: %@", [error localizedDescription]);
    }
    if (error && [_delegate respondsToSelector:@selector(smartConnectionDidFail:)]) {
        [_delegate smartConnectionDidFail:error];
    }
}

#pragma mark - GCDAsyncUdpSocket

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"did send");
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{
    if ([_delegate respondsToSelector:@selector(smartConnectionDidFail:)]) {
        [_delegate smartConnectionDidFail:error];
    }
    NSLog(@"socket closed with error: %@", error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    if (data && !_deviceId) {
        Byte receiveBuffer[1024];
        [data getBytes:receiveBuffer length:1024];
        
        if(receiveBuffer[0]==1){
            NSString *host = nil;
            uint16_t port = 0;
            [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
            
            int contactId = *(int*)(&receiveBuffer[16]);
            //            int type = *(int*)(&receiveBuffer[20]);
            //            int flag = *(int*)(&receiveBuffer[24]);
            
            if (!_deviceId) {
                _deviceId = [NSString stringWithFormat:@"%d", contactId];
                
                if ([_delegate respondsToSelector:@selector(smartConnectionDidReceiveDeviceId:)]) {
                    [_delegate smartConnectionDidReceiveDeviceId:_deviceId];
                }
            }
        }
    }
}

@end
