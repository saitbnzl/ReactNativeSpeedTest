
#import "RNSpeedTest.h"
#import <React/RCTLog.h>


@implementation RNSpeedTest
{
    bool hasListeners;
}

// Will be called when this module's first listener is added.
-(void)startObserving {
    hasListeners = YES;
    // Set up any upstream listeners or background tasks as necessary
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void)stopObserving {
    hasListeners = NO;
    // Remove upstream listeners, stop unnecessary background tasks
}




RCT_EXPORT_MODULE(RNSpeedTest)

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"onCompleteTest", @"onErrorTest", @"onCompleteEpoch", @"onTestCanceled"];
}

RCT_REMAP_METHOD(cancelTest,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    if(self.stage==1){
        [[self.session dataTaskWithURL:self.url] cancel];
    }
    else if(self.stage==2){
        [[self.session dataTaskWithRequest:self.mutableRequest] cancel];
    }
    else if(self.stage==3){
        [self.ping stop];
    }
    resolve(nil);
}

RCT_EXPORT_METHOD(pingTest:(NSString*) urlString timeoutMs:(double)timeoutMs {
    self.url = [NSURL URLWithString:urlString];
    self.startTime = CFAbsoluteTimeGetCurrent();
    self.stopTime = self.startTime;
    self.bytesReceived = 0;
    self.stage = 3;
    
    SimplePing *simplePingClient = [[SimplePing alloc] initWithHostName:@"cloudeos.hiztesti.com.tr"];
    [simplePingClient start];
})

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet
{
    self.startTime=CFAbsoluteTimeGetCurrent();
    RCTLogInfo(@"ping sent at %f", self.startTime);
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
{
    double latency = CFAbsoluteTimeGetCurrent()-self.startTime;
    [self sendEventWithName:@"onCompleteEpoch" body:@{@"speed": @(latency)}];
    RCTLogInfo(@"ping response received at %f", CFAbsoluteTimeGetCurrent());
    //TODO - Do something with latency
}

RCT_EXPORT_METHOD(testDownloadSpeedWithTimeout:(NSString*) urlString epochSize:(int)epochSize timeoutMs:(double)timeoutMs {
    self.url = [NSURL URLWithString:urlString];
    self.startTime = CFAbsoluteTimeGetCurrent();
    self.stopTime = self.startTime;
    self.bytesReceived = 0;
    self.dlEpochSize = epochSize;
    self.dlEpoch = 1;
    self.stage = 1;
    
    NSLog(@"Download test started timeout: %fms epochSize: %d url: %@", timeoutMs, epochSize, urlString);
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.timeoutIntervalForResource = timeoutMs/1000;
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    [[self.session dataTaskWithURL:self.url] resume];
})

RCT_EXPORT_METHOD(testUploadSpeedWithTimeout:(NSString*) urlString epochSize:(int)epochSize timeoutMs:(double)timeoutMs {
    self.url = [NSURL URLWithString:urlString];
    self.startTime = CFAbsoluteTimeGetCurrent();
    self.stopTime = self.startTime;
    self.bytesSent = 0;
    self.dlEpochSize = epochSize;
    self.dlEpoch = 1;
    self.lastElapsed = 0;
    self.stage = 2;

    
    NSLog(@"Upload test started timeout: %fms epochSize: %d url: %@", timeoutMs, epochSize, urlString);
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.timeoutIntervalForResource = timeoutMs/1000;
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:urlString];
    self.mutableRequest = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:timeoutMs/1000.0];
    [self.mutableRequest setHTTPMethod:@"POST"];
    void * bytes = malloc(1024*1024*100);
    NSData * postData = [NSData dataWithBytes:bytes length:1024*1024*100];
    free(bytes);
    [self.mutableRequest setHTTPBody:postData];

    [[self.session dataTaskWithRequest:self.mutableRequest] resume];
})

RCT_EXPORT_METHOD(getNetworkType :(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    
    [reachability startNotifier];
    
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    if(status == NotReachable)
    {
        resolve(@"NONE");
    }
    else if (status == ReachableViaWiFi)
    {
        resolve(@"WIFI");
    }
    else if (status == ReachableViaWWAN)
    {
        CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
        NSString * carrierType = netinfo.currentRadioAccessTechnology;
        if ([carrierType isEqualToString:CTRadioAccessTechnologyGPRS]) {
            resolve(@"2G");
        } else if ([carrierType isEqualToString:CTRadioAccessTechnologyEdge]) {
            resolve(@"2G");
        } else if ([carrierType isEqualToString:CTRadioAccessTechnologyWCDMA]) {
            resolve(@"3G");
        } else if ([carrierType isEqualToString:CTRadioAccessTechnologyHSDPA]) {
            resolve(@"3G");
        } else if ([carrierType isEqualToString:CTRadioAccessTechnologyHSUPA]) {
            resolve(@"3G");
        } else if ([carrierType isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
            resolve(@"2G");
        } else if ([carrierType isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
            resolve(@"3G");
        } else if ([carrierType isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
            resolve(@"3G");
        } else if ([carrierType isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
            resolve(@"3G");
        } else if ([carrierType isEqualToString:CTRadioAccessTechnologyeHRPD]) {
            resolve(@"3G");
        } else if ([carrierType isEqualToString:CTRadioAccessTechnologyLTE]) {
            resolve(@"LTE");
        }
        
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if(self.stage==1){
        NSLog(@"data received %d", (int)[data length]/1024/1024*8);
        self.bytesReceived += (float)[data length];
    
        CFAbsoluteTime elapsed = (CFAbsoluteTimeGetCurrent() - self.startTime);
    
        if(elapsed>0.5){
            CGFloat speed = elapsed != 0 ? self.bytesReceived / elapsed / 1024.0 / 1024.0 * 8 : -1;
            [self sendEventWithName:@"onCompleteEpoch" body:@{@"speed": @(speed)}];
            self.lastElapsed = elapsed;
            self.bytesReceived = 0;
            self.startTime = CFAbsoluteTimeGetCurrent();
        }
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
    didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
    totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    if(self.stage==2){
        NSLog(@"didSendBodyData %ld %ld of %ld", (long)bytesSent, (long)totalBytesSent, (long)totalBytesExpectedToSend);
        CFAbsoluteTime elapsed = (CFAbsoluteTimeGetCurrent() - self.startTime);
        if(elapsed-self.lastElapsed>2){
            CGFloat speed = elapsed != 0 ? totalBytesSent / elapsed / 1024.0 / 1024.0 * 8 : -1;
            [self sendEventWithName:@"onCompleteEpoch" body:@{@"speed": @(speed)}];
            self.lastElapsed = elapsed;
        }
    }
}


-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    NSLog(@"didReceiveResponse");
    self.startTime = CFAbsoluteTimeGetCurrent();
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    CFAbsoluteTime elapsed = self.stopTime - self.startTime;
    CGFloat speed = elapsed != 0 ? self.bytesReceived / elapsed / 1024.0 / 1024.0 * 8 : -1;
    [self sendEventWithName:@"onCompleteTest" body:@{@"speed": @(speed)}];
    // treat timeout as no error (as we're testing speed, not worried about whether we got entire resource or not
    
//    if (error == nil || ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorTimedOut)) {
//        NSLog(@"Download epoch %d of %d: %f", self.dlEpoch, self.dlEpochSize, speed);
//        if(self.dlEpoch<self.dlEpochSize){
//            [[session dataTaskWithURL:self.url] resume];
//            self.dlEpoch += 1;
//            self.startTime = CFAbsoluteTimeGetCurrent();
//            self.bytesReceived = 0;
//
//        }
//        else{
//            [[session dataTaskWithURL:self.url] cancel];
//            if (hasListeners) {
//                [self sendEventWithName:@"onCompleteTest" body:@{@"speed": @(speed)}];
//            }
//        }
//
//    } else {
//        NSLog(@"Test is done: %@", error.userInfo);
//        if(hasListeners){
//            [self sendEventWithName:@"onErrorTest" body:@{@"error": error.userInfo}];
//        }
//
//    }
}

-(void)ping:(GBPing *)pinger didReceiveReplyWithSummary:(GBPingSummary *)summary {
    NSLog(@"REPLY>  %@", summary);
     CFAbsoluteTime elapsed = (CFAbsoluteTimeGetCurrent() - self.startTime);
     [self sendEventWithName:@"onCompleteEpoch" body:@{@"speed": @(elapsed)}];
}

-(void)ping:(GBPing *)pinger didReceiveUnexpectedReplyWithSummary:(GBPingSummary *)summary {
    NSLog(@"BREPLY> %@", summary);
}

-(void)ping:(GBPing *)pinger didSendPingWithSummary:(GBPingSummary *)summary {
    NSLog(@"SENT>   %@", summary);
    self.startTime = CFAbsoluteTimeGetCurrent();
}

-(void)ping:(GBPing *)pinger didTimeoutWithSummary:(GBPingSummary *)summary {
    NSLog(@"TIMOUT> %@", summary);
}

-(void)ping:(GBPing *)pinger didFailWithError:(NSError *)error {
    NSLog(@"FAIL>   %@", error);
}

-(void)ping:(GBPing *)pinger didFailToSendPingWithSummary:(GBPingSummary *)summary error:(NSError *)error {
    NSLog(@"FSENT>  %@, %@", summary, error);
}

@end
  
