
# react-native-speed-test

## Getting started

`$ npm install react-native-speed-test --save`

### Mostly automatic installation

`$ react-native link react-native-speed-test`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-speed-test` and add `RNSpeedTest.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNSpeedTest.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.saitbnzl.rnspeedtest.RNSpeedTestPackage;` to the imports at the top of the file
  - Add `new RNSpeedTestPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-speed-test'
  	project(':react-native-speed-test').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-speed-test/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-speed-test')
  	```

## Usage
```javascript
import RNSpeedTest from 'react-native-speed-test';

// TODO: What to do with the module?
RNSpeedTest;
```
  