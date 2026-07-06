> 模板版本：v0.3.0

<p align="center">
  <h1 align="center"> <code>react-native-cos-sdk</code> </h1>
</p>

本项目基于 [react-native-cos-sdk@1.2.1](https://github.com/TencentCloud/cos-sdk-react-native-plugin) 开发。

请到三方库的 Releases 发布地址查看配套的版本信息：[@react-native-ohos/react-native-cos-sdk Releases](https://github.com/react-native-oh-library/react-native-cos-sdk/releases)。对于未发布到npm的旧版本，请参考[安装指南](/tgz-usage.md)安装tgz包。

| 三方库版本                 | 发布信息                                      |  支持RN版本                 |
| ------------------------- | ------------------------------------------------- |  -------------------------- |
| 1.2.2                 | [@react-native-ohos/react-native-cos-sdk Releases](https://github.com/react-native-oh-library/react-native-cos-sdk/releases)  | 0.72/0.77 |

## 1. 安装与使用

进入到工程目录并输入以下命令：

#### **npm**

```bash
npm install @react-native-ohos/react-native-cos-sdk
```

#### **yarn**

```bash
yarn add @react-native-ohos/react-native-cos-sdk
```

下面的代码展示了这个库的基本使用场景：

> [!WARNING] 使用时 import 的库名不变。

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
        // 首先从您的临时密钥服务器获取包含了密钥信息的响应，例如：
        // 临时密钥服务器 url，临时密钥生成服务请参考 https://cloud.tencent.com/document/product/436/14048
        let stsUrl = "http://stsservice.com/sts";
        let response = null;
        try{
          response = await fetch(stsUrl);
        } catch(e){
          console.error(e);
          return null;
        }
        // 然后解析响应，获取临时密钥信息
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
        // 最后返回临时密钥信息对象
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

此步骤为手动配置原生依赖项的指导。

首先需要使用 DevEco Studio 打开项目里的 HarmonyOS 工程 `harmony`

### 1.在工程根目录的 `oh-package.json5` 添加 overrides 字段

```json
{
  ...
  "overrides": {
    "@rnoh/react-native-openharmony" : "./react_native_openharmony"
  }
}
```

### 2.引入原生端代码

目前有两种方法：

1. 通过 har 包引入（在 IDE 完善相关功能后该方法会被遗弃，目前首选此方法）；
2. 直接链接源码。

方法一：通过 har 包引入（推荐）

> [!TIP] har 包位于三方库安装路径的 `harmony` 文件夹下。

打开 `entry/oh-package.json5`，添加以下依赖

```json
"dependencies": {
    "@rnoh/react-native-openharmony": "file:../react_native_openharmony",
    "@react-native-ohos/react-native-cos-sdk": "file:../../node_modules/@react-native-ohos/react-native-cos-sdk/harmony/rn_cos_sdk.har"
  }
```

点击右上角的 `sync` 按钮

或者在终端执行：

```bash
cd entry
ohpm install
```

方法二：直接链接源码

> [!TIP] 如需使用直接链接源码，请参考[直接链接源码说明](/link-source-code.md)

### 3.配置 CMakeLists 和引入 RNCosSdkPackage

打开 `entry/src/main/cpp/CMakeLists.txt`，添加：

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

打开 `entry/src/main/cpp/PackageProvider.cpp`，添加：

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

### 4.在 ArkTs 侧引入 RNCosSdkPackage

打开 `entry/src/main/ets/RNPackagesFactory.ts`，添加：

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

### 5.运行

点击右上角的 `sync` 按钮

或者在终端执行：

```bash
cd entry
ohpm install
```

然后编译、运行即可。

## 约束与限制

### 兼容性

本文档内容基于以下环境验证通过：

1. RNOH: 0.72.33; SDK：OpenHarmony 5.0.0.71(API Version 12 Release); IDE：DevEco Studio 5.0.3.900; ROM：NEXT.0.0.71;
2. RNOH: 0.77.18; SDK: HarmonyOS 6.0.0 Release SDK; IDE: DevEco Studio  6.0.0.868; ROM: 6.0.0.112;

## 方法

> [!TIP] "Platform" 列表示该属性在原三方库上支持的平台。

> [!TIP] "HarmonyOS Support"列为 yes 表示 HarmonyOS 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

| Name | Description | Type | Required | Platform | HarmonyOS Support |
| ---- | ----------- | ---- | -------- | -------- | ------------------ |
| initWithPlainSecret | 使用永久密钥初始化 SDK(仅测试环境) | function | no | iOS/Android | yes |
| initWithSessionCredentialCallback | 通过回调获取临时安全凭证(生产环境推荐) | function | no | iOS/Android | yes |
| initWithScopeLimitCredentialCallback | 基于 STS 作用域精细化控制权限 | function | no | iOS/Android | yes |
| registerDefaultService | 注册默认 COS 服务实例 | function | no | iOS/Android | yes |
| registerDefaultTransferManger | 注册默认传输管理器 | function | no | iOS/Android | yes |
| registerService | 注册命名 COS 服务实例 | function | no | iOS/Android | yes |
| registerTransferManger | 注册命名传输管理器(支持断点续传) | function | no | iOS/Android | yes |
| enableLogcat | 启用/禁用控制台日志 | function | no | iOS/Android | yes |
| addLogListener | 注册实时日志监听器 | function | no | iOS/Android | yes |
| removeLogListener | 移除日志监听器 | function | no | iOS/Android | yes |
| upload | 上传 | function | no | iOS/Android | yes |
| download | 下载 | function | no | iOS/Android | yes |
| pause | 暂停 | function | no | iOS/Android | yes |
| resume | 恢复执行 | function | no | iOS/Android | yes |
| cancel | 取消传送 | function | no | iOS/Android | yes |
| getPresignedUrl | 获取预签名地址链接 | function | no | iOS/Android | yes |
| headObject | 对象的元数据信息 | function | no | iOS/Android | yes |
| deleteObject | 删除对象 | function | no | iOS/Android | yes |
| getService | 获取桶列表 | function | no | iOS/Android | yes |
| getBucket | 获取桶列表或对象列表 | function | no | iOS/Android | yes |
| headBucket | 检索存储桶及其权限 | function | no | iOS/Android | yes |
| doesBucketExist | 桶是否存在 | function | no | iOS/Android | yes |
| doesObjectExist | 对象是否存在 | function | no | iOS/Android | yes |
| cancelAll | 取消所有队列 | function | no | iOS/Android | yes |
| getObjectUrl | 获取对象的访问路径 | function | no | iOS/Android | yes |
| getBucketLocation | 获取桶所在区域 | function | no | iOS/Android | yes |
| setCloseBeacon | 启用/禁用信标监控功能 | function | no | iOS/Android | no |
| enableLogFile | 启用/禁用本地文件日志 | function | no | iOS/Android | no |
| setMinLevel | 设置全局日志级别 | function | no | iOS/Android | no |
| setLogcatMinLevel | 设置LogCat的最小等级 | function | no | iOS/Android | no |
| setFileMinLevel | 设置文件的最小等级 | function | no | iOS/Android | no |
| setClsMinLevel | 设置CLs的最小等级 | function | no | iOS/Android | no |
| setDeviceID | 设置设备 ID(辅助问题追踪) | function | no | iOS/Android | no |
| setDeviceModel | 设置设备型号 | function | no | iOS/Android | no |
| setAppVersion | 设置应用版本信息 | function | no | iOS/Android | no |
| setExtras | 设置附加元数据 | function | no | iOS/Android | no |
| setLogFileEncryptionKey | 加密本地日志文件 | function | no | iOS/Android | no |
| setCLsChannelAnonymous | 匿名上报日志到腾讯云 CLS | function | no | iOS/Android | no |
| setCLsChannelStaticKey | 用永久密钥上报日志到 CLS | function | no | iOS/Android | no |
| setCLsChannelSessionCredential | 用动态凭证上报日志到 CLS | function | no | iOS/Android | no |
| addSensitiveRule | 添加日志敏感数据脱敏规则 | function | no | iOS/Android | no |
| removeSensitiveRule | 移除敏感数据脱敏规则 | function | no | iOS/Android | no |
| getLogRootDir | 获取日志文件存储目录 | function | no | iOS/Android | no |
| updateCLsChannelSessionCredential | 更新日志渠道会话的凭证 | function | no | iOS/Android | no |
| preBuildConnection | 预构建连接 | function | no | iOS/Android | no |
| putBucket | 创建桶 | function | no | iOS/Android | no |
| deleteBucket | 删除桶 | function | no | iOS/Android | no |
| getBucketAccelerate | 获取桶加速标志 | function | no | iOS/Android | no |
| putBucketAccelerate | 设置桶加速标志 | function | no | iOS/Android | no |
| putBucketVersioning | 设置桶版本控制 | function | no | iOS/Android | no |
| initCustomerDNSFetch | 通过回调动态解析域名 | function | no | iOS/Android | no |
| setDNSFetchIps | 设置DNS解析时自定义获取IP地址 | function | no | iOS/Android | no |
| initCustomerDNS | 配置静态 DNS 映射规则 | function | no | iOS/Android | no |
| getBucketVersioning | 获取桶版本控制 | function | no | iOS/Android | no |
| forceInvalidationCredential | 强制刷新临时凭证 | function | no | iOS/Android | no |
| getService | 获取指定名称的服务实例 | function | no | iOS/Android | yes |
| hasService | 检查服务实例是否存在 | function | no | iOS/Android | yes |
| getTransferManger | 获取指定传输管理器 | function | no | iOS/Android | yes |
| hasTransferManger | 检查传输管理器是否存在 | function | no | iOS/Android | yes |
| hasDefaultService | 是否有默认服务 | function | no | iOS/Android | yes |
| getDefaultService | 获取默认服务 | function | no | iOS/Android | yes |
| hasDefaultTransferManger | 是否有默认传送管理器 | function | no | iOS/Android | yes |
| getDefaultTransferManger | 获取默认传送管理器 | function | no | iOS/Android | yes |

## Known Issues

- [ ] setCloseBeacon、enableLogFile、setMinLevel等接口暂不支持。[issue#1](https://github.com/react-native-oh-library/react-native-cos-sdk/issues/1)

## 其他


## 开源协议

本项目基于 [The MIT License (MIT)](https://github.com/TencentCloud/cos-sdk-react-native-plugin/blob/main/LICENSE) ，请自由地享受和参与开源。
