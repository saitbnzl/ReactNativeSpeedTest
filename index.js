
import { NativeModules, NativeEventEmitter } from 'react-native';

const { RNSpeedTest } = NativeModules;

const RNSpeedTestEvt = new NativeEventEmitter(RNSpeedTest)

console.log("ss module", RNSpeedTest, RNSpeedTestEvt);

export default class SpeedTest {
    static addListener(name, listener) {
        RNSpeedTestEvt.addListener(name, listener);
    }
    static testDownloadSpeedWithTimeout(url, epochSize, timeout){
        RNSpeedTest.testDownloadSpeedWithTimeout(url, epochSize, timeout);
    }
    static async getNetworkType(){
        return RNSpeedTest.getNetworkType();
    }
}
