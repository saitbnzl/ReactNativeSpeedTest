
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
    return @[@"onCompleteTest", @"onErrorTest", @"onCompleteEpoch"];
}

RCT_EXPORT_METHOD(testDownloadSpeedWithTimeout:(NSString*) urlString epochSize:(int)epochSize timeoutMs:(double)timeoutMs {
    self.url = [NSURL URLWithString:urlString];
    self.startTime = CFAbsoluteTimeGetCurrent();
    self.stopTime = self.startTime;
    self.bytesReceived = 0;
    self.dlEpochSize = epochSize;
    self.dlEpoch = 1;
    self.stage = 0;
    
    NSLog(@"Download test started timeout: %fms epochSize: %d url: %@", timeoutMs, epochSize, urlString);
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.timeoutIntervalForResource = timeoutMs/1000;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    [[session dataTaskWithURL:self.url] resume];
})

RCT_EXPORT_METHOD(testUploadSpeedWithTimeout:(NSString*) urlString epochSize:(int)epochSize timeoutMs:(double)timeoutMs {
    self.url = [NSURL URLWithString:urlString];
    self.startTime = CFAbsoluteTimeGetCurrent();
    self.stopTime = self.startTime;
    self.bytesSent = 0;
    self.dlEpochSize = epochSize;
    self.dlEpoch = 1;
    self.lastElapsed = 0;
    self.stage = 1;

    
    NSLog(@"Upload test started timeout: %fms epochSize: %d url: %@", timeoutMs, epochSize, urlString);
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.timeoutIntervalForResource = timeoutMs/1000;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:timeoutMs/1000.0];
    [request setHTTPMethod:@"POST"];
    void * bytes = malloc(1024*1024*100);
    NSData * postData = [NSData dataWithBytes:bytes length:1024*1024*100];
    free(bytes);
    [request setHTTPBody:postData];

    [[session dataTaskWithRequest:request] resume];
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
    if(self.stage==0){
        NSLog(@"data received %d", (int)[data length]/1024/1024*8);
        self.bytesReceived += [data length];
    
        CFAbsoluteTime elapsed = (CFAbsoluteTimeGetCurrent() - self.startTime);
    
        if(elapsed-self.lastElapsed>1){
            CGFloat speed = elapsed != 0 ? self.bytesReceived / elapsed / 1024.0 / 1024.0 * 8 : -1;
            [self sendEventWithName:@"onCompleteEpoch" body:@{@"speed": @(speed)}];
            self.lastElapsed = elapsed;
        }
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
    didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
    totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    if(self.stage==1){
        self.bytesSent += bytesSent;
        NSLog(@"didSendBodyData %ld %ld of %ld", (long)bytesSent, (long)totalBytesSent, (long)totalBytesExpectedToSend);
        CFAbsoluteTime elapsed = (CFAbsoluteTimeGetCurrent() - self.startTime);
        if(elapsed-self.lastElapsed>1){
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
            if (hasListeners) {
                [self sendEventWithName:@"onCompleteTest" body:@{@"speed": @(speed)}];
            }
        }

    } else {
        NSLog(@"Test is done: %@", error.userInfo);
        if(hasListeners){
            [self sendEventWithName:@"onErrorTest" body:@{@"error": error.userInfo}];
        }
        
    }
}

@end
  
