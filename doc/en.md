> > Template version:：v0.3.0

<p align="center">
  <h1 align="center"> <code>react-native-cos-sdk</code> </h1>
</p>

This project is based on [react-native-cos-sdk@1.2.1](https://github.com/TencentCloud/cos-sdk-react-native-plugin).

Please go to the Releases release address of the third-party library to view the supporting version information: [@react-native-ohos/react-native-cos-sdk Releases](https://github.com/react-native-oh-library/react-native-cos-sdk/releases). For older versions that are not published to npm, install the tgz package by referring to the [Installation Guide](/tgz-usage-en.md).

| Version              | Releases info                                     |  Support RN version                |
| ------------------------- | ------------------------------------------------- |  -------------------------- |
| 1.2.2                 | [@react-native-ohos/react-native-cos-sdk Releases](https://github.com/react-native-oh-library/react-native-cos-sdk/releases)  | 0.72/0.77 |

## Installation and Usage

Run the following command in your project directory:

#### **npm**

```bash
npm install @react-native-ohos/react-native-cos-sdk
```

#### **yarn**

```bash
yarn add @react-native-ohos/react-native-cos-sdk
```

The following code shows the basic use scenario of the repository:

> [!WARNING] The name of the imported repository remains unchanged.

```js
import React from 'react';
import {
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  Alert,
} from 'react-native';
import Cos from 'react-native-cos-sdk';

const App = () => {
  const initCos = async () => {
    try {
      console.log('Starting COS initialization...');
      
      Cos.initWithSessionCredentialCallback(async () => {
        // First, get the response containing the key information from your temporary key server, for example:
        // Temporary key server url, please refer to https://cloud.tencent.com/document/product/436/14048 for temporary key generation service
        let stsUrl = "http://stsservice.com/sts";
        let response = null;
        try{
          response = await fetch(stsUrl);
        } catch(e){
          console.error(e);
          return null;
        }
        // Then parse the response to get the temporary key information
        const responseJson = await response.json();
        const credentials = responseJson.credentials;
        const startTime = responseJson.startTime;
        const expiredTime = responseJson.expiredTime;
        const sessionCredentials = {
          tmpSecretId: credentials.tmpSecretId,
          tmpSecretKey: credentials.tmpSecretKey,
          startTime: startTime,
          expiredTime: expiredTime,
          sessionToken: credentials.sessionToken
        };
        console.log(sessionCredentials);
        // Finally return the temporary key information object
        return sessionCredentials;
      });

      Alert.alert('Success', 'COS SDK initialized successfully (check logs for credential callback)');
    } catch (error) {
      console.error('COS init error:', error);
      Alert.alert('Error', 'Failed to initialize COS SDK');
    }
  };

  return (
    <View style={styles.container}>
      <TouchableOpacity onPress={initCos}>
        <Text>Initialize COS SDK</Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default App;

```

## Link

This step provides guidance for manually configuring native dependencies.

Open the `harmony` directory of the HarmonyOS project in DevEco Studio.

### 1. Adding the overrides Field to oh-package.json5 File in the Root Directory of the Project

```json
{
  ...
  "overrides": {
    "@rnoh/react-native-openharmony" : "./react_native_openharmony"
  }
}
```

### 2. Introducing Native Code

Currently, two methods are available:

Method 1 (recommended): Use the HAR file.

> [!TIP] The HAR file is stored in the `harmony` directory in the installation path of the third-party library.

Open `entry/oh-package.json5` file and add the following dependencies:

```json
"dependencies": {
    "@rnoh/react-native-openharmony": "file:../react_native_openharmony",
    "@react-native-ohos/react-native-cos-sdk": "file:../../node_modules/@react-native-ohos/react-native-cos-sdk/harmony/rn_cos_sdk.har"
  }
```

Click the `sync` button in the upper right corner.

Alternatively, run the following instruction on the terminal:

```bash
cd entry
ohpm install
```

Method 2: Directly link to the source code.

> [!TIP] For details, see [Directly Linking Source Code](/link-source-code.md).

### 3. Configuring CMakeLists and Introducing RNCosSdkPackage

Open `entry/src/main/cpp/CMakeLists.txt` and add the following code:

```diff
project(rnapp)
cmake_minimum_required(VERSION 3.4.1)
set(CMAKE_SKIP_BUILD_RPATH TRUE)
set(RNOH_APP_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(NODE_MODULES "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../node_modules")
+ set(OH_MODULES "${CMAKE_CURRENT_SOURCE_DIR}/../../../oh_modules")
set(RNOH_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../../react-native-harmony/harmony/cpp")
set(LOG_VERBOSITY_LEVEL 1)
set(CMAKE_ASM_FLAGS "-Wno-error=unused-command-line-argument -Qunused-arguments")
set(CMAKE_CXX_FLAGS "-fstack-protector-strong -Wl,-z,relro,-z,now,-z,noexecstack -s -fPIE -pie")
set(WITH_HITRACE_SYSTRACE 1) # for other CMakeLists.txt files to use
add_compile_definitions(WITH_HITRACE_SYSTRACE)

add_subdirectory("${RNOH_CPP_DIR}" ./rn)

# RNOH_BEGIN: manual_package_linking_1
add_subdirectory("../../../../sample_package/src/main/cpp" ./sample-package)
+ add_subdirectory("${OH_MODULES}/@react-native-ohos/react-native-cos-sdk/src/main/cpp" ./rnoh-cos-sdk)
# RNOH_END: manual_package_linking_1

file(GLOB GENERATED_CPP_FILES "./generated/*.cpp")

add_library(rnoh_app SHARED
    ${GENERATED_CPP_FILES}
    "./PackageProvider.cpp"
    "${RNOH_CPP_DIR}/RNOHAppNapiBridge.cpp"
)
target_link_libraries(rnoh_app PUBLIC rnoh)

# RNOH_BEGIN: manual_package_linking_2
target_link_libraries(rnoh_app PUBLIC rnoh_sample_package)
+ target_link_libraries(rnoh_app PUBLIC rnoh_cos_sdk)
# RNOH_END: manual_package_linking_2
```

Open `entry/src/main/cpp/PackageProvider.cpp` and add the following code:

```diff
#include "RNOH/PackageProvider.h"
#include "generated/RNOHGeneratedPackage.h"
#include "SamplePackage.h"
+ #include "RNCosSdkPackage.h"

using namespace rnoh;

std::vector<std::shared_ptr<Package>> PackageProvider::getPackages(Package::Context ctx) {
    return {
        std::make_shared<RNOHGeneratedPackage>(ctx),
        std::make_shared<SamplePackage>(ctx),
+       std::make_shared<RNCosSdkPackage>(ctx),
    };
}
```

### Configuring CMakeLists and Introducing RNCosSdkPackage

Open the `entry/src/main/ets/RNPackagesFactory.ts` file and add the following code:

```diff
...
+ import { RNCosSdkPackage } from '@react-native-ohos/react-native-cos-sdk';

export function createRNPackages(ctx: RNPackageContext): RNPackage[] {
  return [
    new SamplePackage(ctx),
+   new RNCosSdkPackage(ctx)
  ];
}
```

### 5. Running

Click the `sync` button in the upper right corner.

Alternatively, run the following instruction on the terminal:

```bash
cd entry
ohpm install
```

Then build and run the code.

## Constraints

### Compatibility

Verified in the following versions:

1. RNOH: 0.72.33; SDK：OpenHarmony 5.0.0.71(API Version 12 Release); IDE：DevEco Studio 5.0.3.900; ROM：NEXT.0.0.71;
2. RNOH: 0.77.18; SDK: HarmonyOS 6.0.0 Release SDK; IDE: DevEco Studio  6.0.0.868; ROM: 6.0.0.112;

## Function

> [!TIP] The **Platform** column indicates the platform where the properties are supported in the original third-party library.

> [!TIP] If the value of **HarmonyOS Support** is **yes**, it means that the HarmonyOS platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

| Name | Description | Type | Required | Platform | HarmonyOS Support |
| ---- | ----------- | ---- | -------- | -------- | ------------------ |
| initWithPlainSecret | Initialize SDK with permanent key (test environment only) | function | no | iOS/Android | yes |
| initWithSessionCredentialCallback | Get temporary security credentials via callback (recommended for production environment) | function | no | iOS/Android | yes |
| initWithScopeLimitCredentialCallback | Fine-grained permission control based on STS scope | function | no | iOS/Android | yes |
| registerDefaultService | Register default COS service instance | function | no | iOS/Android | yes |
| registerDefaultTransferManger | Register default transfer manager | function | no | iOS/Android | yes |
| registerService | Register named COS service instance | function | no | iOS/Android | yes |
| registerTransferManger | Register named transfer manager (supports breakpoint resumption) | function | no | iOS/Android | yes |
| enableLogcat | Enable/Disable console logs | function | no | iOS/Android | yes |
| addLogListener | Register real-time log listener | function | no | iOS/Android | yes |
| removeLogListener | Remove log listener | function | no | iOS/Android | yes |
| upload | Upload | function | no | iOS/Android | yes |
| download | Download | function | no | iOS/Android | yes |
| pause | Pause | function | no | iOS/Android | yes |
| resume | Resume | function | no | iOS/Android | yes |
| cancel | Cancel transfer | function | no | iOS/Android | yes |
| getPresignedUrl | Get pre-signed URL | function | no | iOS/Android | yes |
| headObject | Object metadata information | function | no | iOS/Android | yes |
| deleteObject | Delete object | function | no | iOS/Android | yes |
| getService | Get bucket list | function | no | iOS/Android | yes |
| getBucket | Get bucket list or object list | function | no | iOS/Android | yes |
| headBucket | Retrieve bucket and its permissions | function | no | iOS/Android | yes |
| doesBucketExist | Check if bucket exists | function | no | iOS/Android | yes |
| doesObjectExist | Check if object exists | function | no | iOS/Android | yes |
| cancelAll | Cancel all queues | function | no | iOS/Android | yes |
| getObjectUrl | Get object access path | function | no | iOS/Android | yes |
| getBucketLocation | Get bucket region | function | no | iOS/Android | yes |
| setCloseBeacon | Enable/Disable beacon monitoring function | function | no | iOS/Android | no |
| enableLogFile | Enable/Disable local file logs | function | no | iOS/Android | no |
| setMinLevel | Set global log level | function | no | iOS/Android | no |
| setLogcatMinLevel | Set minimum level for LogCat | function | no | iOS/Android | no |
| setFileMinLevel | Set minimum level for file logs | function | no | iOS/Android | no |
| setClsMinLevel | Set minimum level for CLS | function | no | iOS/Android | no |
| setDeviceID | Set device ID (assist in issue tracking) | function | no | iOS/Android | no |
| setDeviceModel | Set device model | function | no | iOS/Android | no |
| setAppVersion | Set app version information | function | no | iOS/Android | no |
| setExtras | Set additional metadata | function | no | iOS/Android | no |
| setLogFileEncryptionKey | Encrypt local log files | function | no | iOS/Android | no |
| setCLsChannelAnonymous | Report logs anonymously to Tencent Cloud CLS | function | no | iOS/Android | no |
| setCLsChannelStaticKey | Report logs to CLS using permanent key | function | no | iOS/Android | no |
| setCLsChannelSessionCredential | Report logs to CLS using dynamic credentials | function | no | iOS/Android | no |
| addSensitiveRule | Add sensitive data masking rule for logs | function | no | iOS/Android | no |
| removeSensitiveRule | Remove sensitive data masking rule | function | no | iOS/Android | no |
| getLogRootDir | Get log file storage directory | function | no | iOS/Android | no |
| updateCLsChannelSessionCredential | Update credentials for log channel session | function | no | iOS/Android | no |
| preBuildConnection | Pre-build connection | function | no | iOS/Android | no |
| putBucket | Create bucket | function | no | iOS/Android | no |
| deleteBucket | Delete bucket | function | no | iOS/Android | no |
| getBucketAccelerate | Get bucket acceleration flag | function | no | iOS/Android | no |
| putBucketAccelerate | Set bucket acceleration flag | function | no | iOS/Android | no |
| putBucketVersioning | Set bucket versioning | function | no | iOS/Android | no |
| initCustomerDNSFetch | Dynamically resolve domain name via callback | function | no | iOS/Android | no |
| setDNSFetchIps | Set custom IP address for DNS resolution | function | no | iOS/Android | no |
| initCustomerDNS | Configure static DNS mapping rules | function | no | iOS/Android | no |
| getBucketVersioning | Get bucket versioning | function | no | iOS/Android | no |
| forceInvalidationCredential | Force refresh temporary credentials | function | no | iOS/Android | no |
| getService | Get service instance by name | function | no | iOS/Android | yes |
| hasService | Check if service instance exists | function | no | iOS/Android | yes |
| getTransferManger | Get specified transfer manager | function | no | iOS/Android | yes |
| hasTransferManger | Check if transfer manager exists | function | no | iOS/Android | yes |
| hasDefaultService | Check if default service exists | function | no | iOS/Android | yes |
| getDefaultService | Get default service | function | no | iOS/Android | yes |
| hasDefaultTransferManger | Check if default transfer manager exists | function | no | iOS/Android | yes |
| getDefaultTransferManger | Get default transfer manager | function | no | iOS/Android | yes |

## Known Issues

- [ ] setCloseBeacon, enableLogFile, setMinLevel, and similar APIs are not supported at the moment.[issue#1](https://github.com/react-native-oh-library/react-native-cos-sdk/issues/1)

## Others

## License

This project is licensed under [The MIT License (MIT)](https://github.com/TencentCloud/cos-sdk-react-native-plugin/blob/main/LICENSE).