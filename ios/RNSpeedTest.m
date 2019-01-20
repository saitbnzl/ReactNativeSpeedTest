
#import "RNSpeedTest.h"

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


- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE(RNSpeedTest)

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"onCompleteDownloadTest",@"onCompleteUploadTest",@"onCompletePingTest", @"onErrorDownloadTest", @"onErrorUploadTest", @"onErrorPingTest"];
}

RCT_EXPORT_METHOD(testDownloadSpeedWithTimeout:(NSString*) urlString epochSize:(int)epochSize timeoutMs:(double)timeoutMs {
    self.url = [NSURL URLWithString:urlString];
    self.startTime = CFAbsoluteTimeGetCurrent();
    self.stopTime = self.startTime;
    self.bytesReceived = 0;
    self.dlEpochSize = epochSize;
    self.dlEpoch = 1;
    NSLog(@"Download test started timeout: %fms epochSize: %d url: %@", timeoutMs, epochSize, urlString);
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.timeoutIntervalForResource = timeoutMs/1000;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    [[session dataTaskWithURL:self.url] resume];
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
    //NSLog(@"data received %d", (int)[data length]);
    self.bytesReceived += [data length];
    self.stopTime = CFAbsoluteTimeGetCurrent();
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    self.startTime = CFAbsoluteTimeGetCurrent();
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    CFAbsoluteTime elapsed = self.stopTime - self.startTime;
    CGFloat speed = elapsed != 0 ? self.bytesReceived / (CFAbsoluteTimeGetCurrent() - self.startTime) / 1024.0 / 1024.0 * 8 : -1;
    
    // treat timeout as no error (as we're testing speed, not worried about whether we got entire resource or not
    
    if (error == nil || ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorTimedOut)) {
        NSLog(@"Download epoch %d of %d: %f", self.dlEpoch, self.dlEpochSize, speed);
        if(self.dlEpoch<self.dlEpochSize){
            [[session dataTaskWithURL:self.url] resume];
            self.dlEpoch += 1;
            self.startTime = CFAbsoluteTimeGetCurrent();
            self.bytesReceived = 0;
        }
        else{
            [[session dataTaskWithURL:self.url] cancel];
        }
        if (hasListeners) {
            [self sendEventWithName:@"onCompleteDownloadTest" body:@{@"speed": @(speed)}];
        }
    } else {
        NSLog(@"Download test is done: %@", error.userInfo);
        if(hasListeners){
            [self sendEventWithName:@"onErrorDownloadTest" body:@{@"error": error.userInfo}];
        }
        
    }
}

@end
  
