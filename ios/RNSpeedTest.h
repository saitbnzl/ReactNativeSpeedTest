
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import "Reachability.h"
#import<CoreTelephony/CTTelephonyNetworkInfo.h>

#endif
Reachability* reachability;

@interface RNSpeedTest : RCTEventEmitter <RCTBridgeModule, NSURLSessionDelegate, NSURLSessionDataDelegate>
@property (nonatomic) CFAbsoluteTime startTime;
@property (nonatomic) CFAbsoluteTime stopTime;
@property (nonatomic) NSURL *url;
@property (nonatomic) long long bytesReceived;
@property (nonatomic) long long bytesSent;
@property (nonatomic) int dlEpoch;
@property (nonatomic) int dlEpochSize;
@end
  
