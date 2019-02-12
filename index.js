
import { NativeModules, NativeEventEmitter, Platform } from 'react-native';

const { RNSpeedTest } = NativeModules;

const RNSpeedTestEvt = new NativeEventEmitter(RNSpeedTest)

console.log("ss module", RNSpeedTest, RNSpeedTestEvt);

export default class SpeedTest {
    static addListener(name, listener) {
        RNSpeedTestEvt.addListener(name, listener);
    }
    static testDownloadSpeedWithTimeout(url, epochSize, timeout, reportInterval) {
        if (Platform.OS === 'ios')
            RNSpeedTest.testDownloadSpeedWithTimeout(url, epochSize, timeout);
        else if (Platform.OS === 'android') {
            RNSpeedTest.testDownloadSpeed(url, timeout, reportInterval);
        }
    }
    static testUploadSpeedWithTimeout(url, epochSize, timeout, reportInterval) {
        if (Platform.OS === 'ios')
            RNSpeedTest.testUploadSpeedWithTimeout(url, epochSize, timeout);
        else if (Platform.OS === 'android') {
            RNSpeedTest.testUploadSpeed(url, timeout, reportInterval)
        }
    }
    static testPing(url, timeout) {
        if (Platform.OS === 'ios')
            RNSpeedTest.pingTest(url, timeout);
        else if (Platform.OS === 'android') {
            RNSpeedTest.pingTest(url, timeout);
        }
    }
    static async getNetworkType() {
        return RNSpeedTest.getNetworkType();
    }
}
