
package com.saitbnzl.rnspeedtest;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import fr.bmartel.speedtest.SpeedTestReport;
import fr.bmartel.speedtest.SpeedTestSocket;
import fr.bmartel.speedtest.inter.ISpeedTestListener;
import fr.bmartel.speedtest.model.SpeedTestError;

public class RNSpeedTestModule extends ReactContextBaseJavaModule {
  private ReactContext reactContext;
  private SpeedTestSocket mSpeedTestSocket;

  public RNSpeedTestModule(final ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    mSpeedTestSocket = new SpeedTestSocket();
    mSpeedTestSocket.addSpeedTestListener(new ISpeedTestListener() {
      @Override
      public void onCompletion(SpeedTestReport report) {
        // called when download/upload is complete
        System.out.println("[COMPLETED] rate in octet/s : " + report.getTransferRateOctet());
        System.out.println("[COMPLETED] rate in bit/s   : " + report.getTransferRateBit());
        WritableMap payload = Arguments.createMap();
        payload.putString("mbps",  String.valueOf(report.getTransferRateBit().doubleValue()/1000000));
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("onCompleteTest", payload);
      }

      @Override
      public void onError(SpeedTestError speedTestError, String errorMessage) {
        // called when a download/upload error occur
        WritableMap payload = Arguments.createMap();
        payload.putString("name", speedTestError.name());
                reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("onErrorTest", payload);
      }

      @Override
      public void onProgress(float percent, SpeedTestReport report) {
        // called to notify download/upload progress
        System.out.println("[PROGRESS] progress : " + percent + "%");
        System.out.println("[PROGRESS] rate in octet/s : " + report.getTransferRateOctet());
        System.out.println("[PROGRESS] rate in bit/s   : " + report.getTransferRateBit());
        WritableMap payload = Arguments.createMap();
        payload.putString("mbps", String.valueOf(report.getTransferRateBit().doubleValue()/1000000));
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("onCompleteEpoch", payload);
      }
    });
  }

  @ReactMethod
  public void testDownloadSpeed(String url, int timeout, int reportInterval){
    mSpeedTestSocket.startFixedDownload(url,timeout,reportInterval);
  }

  @Override
  public String getName() {
    return "RNSpeedTest";
  }
}