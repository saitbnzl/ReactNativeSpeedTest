
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import "Reachability.h"
#import<CoreTelephony/CTTelephonyNetworkInfo.h>
#import "GBPing/GBPing.h"
#endif
Reachability* reachability;

@interface RNSpeedTest : RCTEventEmitter <RCTBridgeModule, NSURLSessionDelegate, NSURLSessionDataDelegate, GBPingDelegate>
@property (nonatomic) CFAbsoluteTime startTime;
@property (nonatomic) CFAbsoluteTime stopTime;
@property (nonatomic) CFAbsoluteTime lastElapsed;
@property (nonatomic) NSURL *url;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) long long bytesReceived;
@property (nonatomic) long long bytesSent;
@property (nonatomic) int dlEpoch;
@property (nonatomic) int dlEpochSize;
@property (nonatomic) int pingTimeout;
@property (nonatomic) int stage;
@property (strong, nonatomic) GBPing *ping;
@end
  
