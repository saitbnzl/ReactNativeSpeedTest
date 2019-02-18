#import "SimplePing.h"

@interface SimplePingClient : NSObject<SimplePingDelegate>

+(void)pingHostname:(NSString*)hostName andResultCallback:(void(^)(NSString* latency))result;

@end

@interface SimplePingClient()
{
    SimplePing* _pingClient;
    NSDate* _dateReference;
}

@property(nonatomic, strong) void(^resultCallback)(NSString* latency);

@end

@implementation SimplePingClient

+(void)pingHostname:(NSString*)hostName andResultCallback:(void(^)(NSString* latency))result
{
    static SimplePingClient* singletonPC = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singletonPC = [[SimplePingClient alloc] init];
    });
    
    //ping hostname
    [singletonPC pingHostname:hostName andResultCallBlock:result];
}

-(void)pingHostname:(NSString*)hostName andResultCallBlock:(void(^)(NSString* latency))result
{
    _resultCallback = result;
    _pingClient = [SimplePing initWithHostName:hostName];
    _pingClient.delegate = self;
    [_pingClient start];
}

#pragma mark - SimplePingDelegate methods
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
{
    [pinger sendPingWithData:nil];
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error
{
    _resultCallback(nil);
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet
{
    _dateReference = [NSDate date];
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error
{
    [pinger stop];
    _resultCallback(nil);
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
{
    [pinger stop];
    NSDate *end=[NSDate date];
    double latency = [end timeIntervalSinceDate:_dateReference] * 1000;//get in miliseconds
    _resultCallback([NSString stringWithFormat:@"%.f", latency]);
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet
{
    [pinger stop];
    _resultCallback(nil);
}

@end


