/**
 * MIT License
 *
 * Copyright (C) 2025 Huawei Device Co., Ltd.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import { AnyThreadTurboModule } from '@rnoh/react-native-openharmony/ts';
import {
  CommonPrefixes,
  CosXmlBaseService,
  CosXmlServiceConfig,
  GetBucketObjectVersionsResult,
  ListBucketsResult,
  ListObjectsRequest,
  ListObjectsResult,
  QCloudCredential,
  Content,
  HeadBucketResult,
  HeadObjectResult
} from '@tencentcloud/cos';

import { DownloadTask, GetObjectRequest, HttpProgress, CosXmlDownloadTaskResult, CosError } from '@tencentcloud/cos';
import {
  PutObjectRequest,
  UploadTask,
  CosXmlUploadTaskResult,
  CosXmlRequest,
  GetBucketTagRequest,
  GetBucketObjectVersionsRequest,
  ListBucketsRequest
} from '@tencentcloud/cos';
import { TransferConfig } from '@tencentcloud/cos';
import {
  PresignedUrlRequest, HeadObjectRequest, DeleteObjectRequest
} from '@tencentcloud/cos';
import {
  COS_EMITTER_DNS_FETCH,
  COS_EMITTER_INIT_MULTIPLE_UPLOAD_CALLBACK,
  COS_EMITTER_LOG_CALLBACK,
  COS_EMITTER_PROGRESS_CALLBACK,
  COS_EMITTER_RESULT_FAIL_CALLBACK,
  COS_EMITTER_RESULT_SUCCESS_CALLBACK,
  COS_EMITTER_STATE_CALLBACK,
  COS_EMITTER_UPDATE_CLS_SESSION_CREDENTIAL,
  COS_EMITTER_UPDATE_SESSION_CREDENTIAL,
  InitMultipleUploadEvent,
  LogEvent,
  TransferProgressEvent,
  TransferResultFailEvent,
  TransferResultSuccessEvent,
  TransferStateEvent,
  UpdateSessionCredentialEvent
} from './events'
import { QCloudLogger } from '@tencentcloud/cos';
import http from '@ohos.net.http';
import { CredentialCallBack } from '@tencentcloud/cos';
import { BusinessError } from '@ohos.base';
import { Logger } from './Logger';
import json from '@ohos.util.json';
import util from '@ohos.util';
import rcp from '@hms.collaboration.rcp'
import { HeadBucketRequest } from '@tencentcloud/cos/src/main/ets/model/bucket/HeadBucketRequest';
import hilog from '@ohos.hilog'
import connection from '@ohos.net.connection';

const TAG = '[QCloudCosReactNative]';

export class DnsMapParameters {
  domain: string = '';
  ips: Array<string> = [];
}

interface BucketInfo {
  name: string;
  location: string;
  creationDate: string;
  bucketType: string;
}

class TransferManager {
  service: CosXmlBaseService;
  config?: ESObject;

  constructor(service: CosXmlBaseService, config?: ESObject) {
    this.service = service;
    this.config = config;
  }
}

export class StsSessionQCloudCredentials {
  credentials: StsCredentials;
  startTime: number;
  expiredTime: number;

  constructor(credentials: StsCredentials, startTime: number, expiredTime: number) {
    this.credentials = credentials;
    this.startTime = startTime;
    this.expiredTime = expiredTime;
  }
}

export class StsCredentials {
  tmpSecretId: string;
  tmpSecretKey: string;
  sessionToken: string;

  constructor(tmpSecretId: string, tmpSecretKey: string, sessionToken: string) {
    this.tmpSecretId = tmpSecretId;
    this.tmpSecretKey = tmpSecretKey;
    this.sessionToken = sessionToken;
  }
}

export interface STSCredentialScope {
  action: string,
  region: string,
  bucket: string,
  prefix: string
}

export class RNCosSdkModule extends AnyThreadTurboModule {
  // 静态配置自定义dns
  private dnsMap: Map<string, string[]> = new Map();
  // dnsMap: DnsMapParameters[] = [];
  // 动态dns fetch
  private initDnsFetch: boolean = false;
  private DEFAULT_KEY: string = '';
  private cosServices: Map<string, CosXmlBaseService> = new Map();
  private transferManagers: Map<string, ESObject> = new Map();
  private taskMap: Map<string, ESObject> = new Map();
  private credential: QCloudCredential| undefined = undefined;
  private region: string = '';

  private buildCosXmlService(config: ESObject): CosXmlBaseService {
    let service: CosXmlBaseService = CosXmlBaseService.default();

    let configs: CosXmlServiceConfig = service.cosXmlServiceConfig;
    if (config.region) {
      configs.region = config.region;
    }
    if (config.connectionTimeout) {
      configs.connectTimeout = config.connectionTimeout;
    }
    if (config.socketTimeout) {
    }
    if (config.isHttps) {
    }
    if (config.domainSwitch) {
    }
    if (config.host) {
      configs.host = config.host;
    }
    if (config.hostFormat) {
    }
    if (config.port) {
      configs.port = config.port;
    }
    if (config.isDebuggable) {
      CosXmlBaseService.setDebuggable(config.isDebuggable);
    }
    if (config.signInUrl) {
    }
    if (config.dnsCache) {
    }
    if (config.accelerate) {
    }
    if (config.userAgent) {
    }
    if (this.initDnsFetch) {
      // this.ctx.rnInstance.emitDeviceEvent(COS_EMITTER_DNS_FETCH, {}); // domain
    }
    return service;
  }

  private buildTransferManager(config: ESObject, transferConfig: ESObject): TransferManager {
    let cosXmlService: CosXmlBaseService = this.buildCosXmlService(config);
    let transferManager: TransferManager = new TransferManager(cosXmlService, transferConfig);
    return transferManager;
  }

  private getTransferManager(transferKey: string): TransferManager {
    if (this.transferManagers.has(transferKey)) {
      return this.transferManagers.get(transferKey);
    } else {
      let key: string = this.DEFAULT_KEY === transferKey ? "default" : transferKey;
      throw new Error(key + " TransferManager unregistered, Please register first");
    }
  }

  async initWithPlainSecret(secretId: string, secretKey: string): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      let cosXmlServiceConfig = new CosXmlServiceConfig('ap-chengdu');
      CosXmlBaseService.initDefaultService(
        this.ctx.uiAbilityContext,
        cosXmlServiceConfig,
        (request) => {
          return new Promise((resolve, reject) => {
            let credential: QCloudCredential = new QCloudCredential();
            credential.secretID = secretId;
            credential.secretKey = secretKey;
            this.credential = credential;
            resolve(credential)
          })
        }
      )

      resolve(null);
    });
    return promise;
  }

  async initWithSessionCredentialCallback(): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      this.ctx.rnInstance.emitDeviceEvent(COS_EMITTER_UPDATE_SESSION_CREDENTIAL, {});
      resolve(null);
    });
    return promise;
  }

  async initWithScopeLimitCredentialCallback(): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      const arr: Array<STSCredentialScope> = []
      this.ctx.rnInstance.emitDeviceEvent(COS_EMITTER_UPDATE_SESSION_CREDENTIAL, {
        stsScopesArrayJson: JSON.stringify(arr)
      });
      resolve(null);
    });
    return promise;
  }

  // not support
  async initCustomerDNS(dnsArray: DnsMapParameters[]): Promise<void> {
    this.dnsMap = new Map();
    for (let i = 0; i < dnsArray.length; i++) {
      let dns: DnsMapParameters = dnsArray[i];
      let ipsArray: Array<string> = dns.ips;
      if (dns && ipsArray) {
        this.dnsMap.set(dns.domain, ipsArray);
      }
    }

    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async initCustomerDNSFetch(): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      this.initDnsFetch = true;
      // this.ctx.rnInstance.emitDeviceEvent(COS_EMITTER_DNS_FETCH, ips);
      resolve(null);
    });
    return promise;
  }

  // not support
  async forceInvalidationCredential(): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async setCloseBeacon(isCloseBeacon: boolean): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  async registerDefaultService(config: ESObject): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      if(this.credential){
        CosXmlBaseService.initDefaultService(
          this.ctx.uiAbilityContext,
          new CosXmlServiceConfig(config.region),
          (request) => {
            return new Promise<QCloudCredential>(resolve => {
              if(this.credential){
                resolve(this.credential)
              } else {
                reject(null)
              }
            })
          }
        )
      }
      
      let service: CosXmlBaseService = CosXmlBaseService.default();
      this.cosServices.set(this.DEFAULT_KEY, service);
      resolve(null);
    });
    return promise;
  }

  private async function () {
    return new Promise<QCloudCredential>((resolve, reject) => {
      if(this.credential){
        resolve(this.credential)
      }else {
        reject(null)
      }
    })
  }

  async registerDefaultTransferManger(config: ESObject, transferConfig: ESObject): Promise<ESObject> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      let transferManager = this.buildTransferManager(config, transferConfig);
      this.transferManagers.set(this.DEFAULT_KEY, transferManager);
      resolve(null);
    });
    return promise;
  }

  async registerService(key: string, config: ESObject): Promise<ESObject> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      if (!!!key) {
        reject(new Error("register key cannot be empty"));
      }
      let service: CosXmlBaseService = this.buildCosXmlService(config);
      this.cosServices.set(key, service);
      let result = '';
      resolve(result);
    });
    return promise;
  }

  async registerTransferManger(key: string, config: ESObject, transferConfig: ESObject): Promise<ESObject> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      if (!!!key) {
        reject(new Error("register key cannot be empty"));
      }
      let transferManager = this.buildTransferManager(config, transferConfig);
      this.transferManagers.set(key, transferManager);
      let result = '';
      resolve(result);
    });
    return promise;
  }

  async enableLogcat(enable: boolean): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      CosXmlBaseService.setDebuggable(enable);
      resolve(null);
    });
    return promise;
  }

  // not support
  async enableLogFile(enable: boolean): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  private parseLogToMessage(log: string): string | object {
    const lines = log.split('\n');
    const messageLines: string[] = [];

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      // 跳过装饰行
      if (line.startsWith('┌') || line.startsWith('└')) {
        continue;
      }

      // 找到第一个消息行
      if (line.startsWith('|    ')) {
        // 收集所有连续的消息行
        for (let j = i; j < lines.length; j++) {
          const messageLine = lines[j];
          if (messageLine.startsWith('|    ')) {
            // 移除"|    "前缀，保留缩进
            const content = messageLine.substring(5);
            messageLines.push(content);
          } else {
            // 遇到非消息行，停止收集
            break;
          }
        }
        break;
      }
    }

    if (messageLines.length === 0) {
      return "";
    }

    const joinedMessage = messageLines.join('\n');
    try {
      return JSON.parse(joinedMessage) || "";
    } catch {
      // 如果解析失败，返回原始字符串
      return joinedMessage;
    }
  }

  async addLogListener(key: string): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {

      QCloudLogger.logOutputCallback = (log: string) => {
        if (key) {
          let msg = this.parseLogToMessage(log);
          this.ctx.rnInstance.emitDeviceEvent(COS_EMITTER_LOG_CALLBACK, {
            key: key,
            logEntityJson: JSON.stringify({
              timestamp: new Date().getTime(),
              level: hilog.LogLevel.INFO,
              category: 1,
              tag: '',
              // message: msg,
              message: log,
              threadName: '',
              extras: "{ qcloud_platform: 'harmony' }",
              // extras?: Record<string, string>;
              // throwable?: string;
            })
          });
        }
      }

      resolve(null);
    });
    return promise;
  }

  async removeLogListener(key: string): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      QCloudLogger.logOutputCallback = undefined;
      resolve(null);
    });
    return promise;
  }

  // not support
  async setMinLevel(minLevel: number): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async setLogcatMinLevel(minLevel: number): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async setFileMinLevel(minLevel: number): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async setClsMinLevel(minLevel: number): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async setDeviceID(deviceID: string): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async setDeviceModel(deviceModel: string): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async setAppVersion(appVersion: string): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async setExtras(extras: ESObject): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async setLogFileEncryptionKey(key: ESObject, iv: ESObject): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async setCLsChannelAnonymous(topicId: string, endpoint: string): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async setCLsChannelStaticKey(topicId: string, endpoint: string, secretId: string, secretKey: string): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async setCLsChannelSessionCredential(topicId: string, endpoint: string): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async addSensitiveRule(ruleName: string, regex: string): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async removeSensitiveRule(ruleName: string): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async getLogRootDir(): Promise<string> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      let result = '';
      resolve(result);
    });
    return promise;
  }

  async updateSessionCredential(credentials: ESObject, scopesArray: null | string): Promise<void> {
    let credential: QCloudCredential = new QCloudCredential();
    credential.expirationDate = new Date(credentials.expiredTime * 1000);
    credential.secretID = credentials.tmpSecretId;
    credential.secretKey = credentials.tmpSecretKey;
    credential.token = credentials.sessionToken;
    credential.startDate = new Date(credentials.startTime * 1000);
    this.credential = credential;

    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async setDNSFetchIps(domain: string, ips: null | string[]): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async updateCLsChannelSessionCredential(credentials: ESObject): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // Required for rn built in EventEmitter Calls.
  addListener(eventName: string): void {
  }

  // Required for rn built in EventEmitter Calls.
  removeListeners(count: number): void {
  }

  uploadTask?: UploadTask;
  uploadId?: string = undefined;
  downloadTask?: DownloadTask;
  pauseFlag: boolean = true;

  async upload(
    transferKey: string,
    bucket: string,
    cosPath: string,
    fileUri: string,
    uploadId: string,
    resultCallbackKey: string,
    stateCallbackKey: string,
    progressCallbackKey: string,
    InitMultipleUploadCallbackKey: string,
    stroageClass: string,
    trafficLimit: string,
    region: string,
    credentials: ESObject
  ): Promise<string> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      let putReqeust = new PutObjectRequest(bucket, cosPath, fileUri);
      putReqeust.region = region;
      let transferManager: TransferManager = this.getTransferManager(transferKey);
      let config: TransferConfig = new TransferConfig();
      if (transferManager?.config) {
        config.simpleUploadLimit = transferManager.config?.divisionForUpload;
        config.sliceLength = transferManager.config?.sliceSizeForUpload;
      }

      let task: UploadTask = transferManager?.service?.upload(putReqeust, uploadId, config);
      task.onProgress = (progress: HttpProgress) => {
        this.ctx.rnInstance.emitDeviceEvent(COS_EMITTER_PROGRESS_CALLBACK, {
          "transferKey": transferKey,
          "callbackKey": progressCallbackKey,
          "complete": progress.complete,
          "target": progress.target
        });
      };
      task.onTimeInfo = (request: CosXmlRequest, timeInfo: rcp.TimeInfo) => {
      }
      task.onResult = {
        onSuccess: (request, result: CosXmlUploadTaskResult) => {
          this.uploadId = undefined;
          if (this.taskMap.has(taskKey)) {
            this.taskMap.delete(taskKey);
          }

          let crc64ecma = '';
          if (result?.headers) {
            crc64ecma = result.headers["x-cos-hash-crc64ecma"];
          }

          this.ctx.rnInstance.emitDeviceEvent(COS_EMITTER_RESULT_SUCCESS_CALLBACK, {
            "transferKey": transferKey,
            "callbackKey": resultCallbackKey,
            "headers": {
              "accessUrl": result?.accessUrl,
              "eTag": result?.eTag,
              "crc64ecma": crc64ecma
            }
          });
        },
        onFail: (request, error: CosError) => {
          this.ctx.rnInstance.emitDeviceEvent(COS_EMITTER_RESULT_FAIL_CALLBACK, {
            "transferKey": transferKey,
            "callbackKey": resultCallbackKey,
            "clientException": {
              "errorCode": error.cosErrorCode,
              "message": error.message
            },
            "serviceException": {
              "statusCode": '',
              "httpMsg": '',
              "requestId": '',
              "serviceName": '',
              "errorCode": '',
              "errorMessage": ''
            }
          });
        }
      }
      task.initCallBack = (uploadId: string) => {
        this.uploadId = uploadId;
      }
      this.setRequestCredential(credentials, putReqeust);
      let taskKey = "upload-" + util.generateRandomUUID();
      this.taskMap.set(taskKey, task);
      task.start();
      resolve(taskKey);
    });
    return promise;
  }


  async download(
    transferKey: string,
    bucket: string,
    cosPath: string,
    savePath: string,
    resultCallbackKey: string,
    stateCallbackKey: string,
    progressCallbackKey: string,
    versionId: string,
    trafficLimit: string,
    region: string,
    credentials: ESObject
  ): Promise<string> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      try {
        let transferManager: TransferManager = this.getTransferManager(transferKey);
        let getRequest = new GetObjectRequest(bucket, cosPath, savePath);

        if (region) {
          getRequest.region = region;
        }
        if (versionId) {
          getRequest.addHeader("versionId", (versionId).toString());
        }
        if (trafficLimit) {
          getRequest.addHeader("x-cos-traffic-limit", (trafficLimit).toString());
        }
        this.setRequestCredential(credentials, getRequest);
        let task: DownloadTask = transferManager.service?.download(getRequest);
        task.onProgress = (progress: HttpProgress) => {
          this.ctx.rnInstance.emitDeviceEvent(COS_EMITTER_PROGRESS_CALLBACK, {
            "transferKey": transferKey,
            "callbackKey": progressCallbackKey,
            "complete": progress.complete,
            "target": progress.target
          });
        };
        task.onResult = {
          onSuccess: (request, result: CosXmlDownloadTaskResult) => {
            this.uploadId = undefined;
            if (this.taskMap.has(taskKey)) {
              this.taskMap.delete(taskKey);
            }

            let headers: Record<string, string> | undefined = result.headers;
            this.ctx.rnInstance.emitDeviceEvent(COS_EMITTER_RESULT_SUCCESS_CALLBACK, {
              "transferKey": transferKey,
              "callbackKey": resultCallbackKey,
              "headers": headers
            });
          },
          onFail: (request, error: CosError) => {
            this.ctx.rnInstance.emitDeviceEvent(COS_EMITTER_RESULT_FAIL_CALLBACK, {
              "transferKey": transferKey,
              "callbackKey": resultCallbackKey,
              "clientException": {
                "errorCode": error.cosErrorCode,
                "message": error.message
              },
              "serviceException": {
                "statusCode": '',
                "httpMsg": '',
                "requestId": '',
                "serviceName": '',
                "errorCode": '',
                "errorMessage": ''
              }
            });
          }
        }
        task.start();
        let taskKey = 'download-' + util.generateRandomUUID();
        this.taskMap.set(taskKey, task);
        resolve(taskKey);
      } catch (e) {
        Logger.error("cos_sdk download err:"+JSON.stringify(e))
        reject(null);
      }
    });
    return promise;
  }

  async pause(transferKey: string, taskId: string): Promise<void> {
    if (taskId && taskId.startsWith("upload-")) {
      let task: UploadTask = this.taskMap.get(taskId);
      if (task) {
        task.pause();
      }
    } else if (taskId && taskId.startsWith("download-")) {
      let task: DownloadTask = this.taskMap.get(taskId);
      if (task) {
        task.pause();
      }
    }

    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  async resume(transferKey: string, taskId: string): Promise<void> {
    if (taskId && taskId.startsWith("upload-")) {
      let task: UploadTask = this.taskMap.get(taskId);
      if (task) {
        task.resume();
      }
    } else if (taskId && taskId.startsWith("download-")) {
      let task: DownloadTask = this.taskMap.get(taskId);
      if (task) {
        task.resume();
      }
    }

    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  async cancel(transferKey: string, taskId: string): Promise<void> {
    if (taskId && taskId.startsWith("upload-")) {
      let task: UploadTask = this.taskMap.get(taskId);
      if (task) {
        task.cancel();
      }
    } else if (taskId && taskId.startsWith("download-")) {
      let task: DownloadTask = this.taskMap.get(taskId);
      if (task) {
        task.cancel();
      }
    }

    if (this.taskMap.has(taskId)) {
      this.taskMap.delete(taskId);
    }

    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  private getCosXmlService(serviceKey: string): CosXmlBaseService | undefined {
    if (this.cosServices.has(serviceKey)) {
      return this.cosServices.get(serviceKey);
    } else {
      let key: string = this.DEFAULT_KEY === (serviceKey) ? "default" : serviceKey;
      throw new Error(key);
    }
  }

  private setRequestCredential(sessionCredentials: QCloudCredential, request: CosXmlRequest) {
    if (sessionCredentials) {
      let credentials: QCloudCredential;
      if (!sessionCredentials.startDate) {
        credentials = new QCloudCredential();
        credentials.secretID = sessionCredentials.secretID;
        credentials.secretKey = sessionCredentials.secretKey;
        credentials.token = sessionCredentials.token;
        credentials.expirationDate = sessionCredentials.expirationDate;
      } else {
        credentials = new QCloudCredential();
        credentials.secretID = sessionCredentials.secretID;
        credentials.secretKey = sessionCredentials.secretKey;
        credentials.token = sessionCredentials.token;
        credentials.startDate = sessionCredentials.startDate;
        credentials.expirationDate = sessionCredentials.expirationDate;
      }
      request.credential = credentials;
    }
  }

  async getObjectUrl(serviceKey: string, bucket: string, cosPath: string, region: string): Promise<string> {
    let service: CosXmlBaseService | undefined = this.getCosXmlService(serviceKey);
    let request = new GetObjectRequest(bucket, cosPath, region);
    let result = service?.getAccessUrl(request);

    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      if (result) {
        resolve(result);
      } else {
        reject(null)
      }
    });
    return promise;
  }

  async getPresignedUrl(
    serviceKey: string,
    bucket: string,
    cosPath: string,
    signValidTime: string,
    signHost: string,
    parameters: ESObject,
    region: string,
    credentials: ESObject
  ): Promise<string> {
    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      let service: CosXmlBaseService | undefined = this.getCosXmlService(serviceKey);
      let presignedUrlRequest: PresignedUrlRequest =
        new PresignedUrlRequest(bucket, cosPath);
      presignedUrlRequest.requestMethod = http.RequestMethod.GET;
      if (signValidTime) {
      }

      if (signHost) {
        presignedUrlRequest.addNoSignHeaderKey("Host")
      }
      if (parameters) {
        let parametersMap: Map<string, string> = new Map();
        presignedUrlRequest.addQueries(parametersMap);
      }

      if (region) {
        presignedUrlRequest.region = region;
      }

      this.setRequestCredential(credentials, presignedUrlRequest);
      let urlWithSign: string = '';
      if (service) {
        let r = await service?.buildPresignedUrl(presignedUrlRequest);
        if (r) {
          urlWithSign = r;
        }
      }
      resolve(urlWithSign);
    });
    return promise;
  }

  async headObject(serviceKey: string,
    bucket: string,
    cosPath: string,
    region?: string,
    versionId?: string,
    credentials?: ESObject): Promise<ESObject> {
    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      let service: CosXmlBaseService | undefined = this.getCosXmlService(serviceKey);
      let headObjectRequest: HeadObjectRequest = new HeadObjectRequest(bucket, cosPath);
      if (region) {
        headObjectRequest.region = region;
      }
      if (versionId) {
      }
      this.setRequestCredential(credentials, headObjectRequest);
      let result: ESObject = undefined;
      try {
        let resultTmp = await service?.headObject(headObjectRequest);
        result = resultTmp?.headers;
        resolve(result);
      } catch (e) {
        reject(e);
      }

    });
    return promise;
  }

  async deleteObject(serviceKey: string, bucket: string, cosPath: string, region?: string,
    versionId?: string, credentials?: ESObject): Promise<void> {
    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      let service: CosXmlBaseService | undefined = this.getCosXmlService(serviceKey);
      let deleteObjectRequest: DeleteObjectRequest = new DeleteObjectRequest(bucket, cosPath);
      if (region) {
        deleteObjectRequest.region = region;
      }
      if (versionId) {
      }
      this.setRequestCredential(credentials, deleteObjectRequest);
      let result = await service?.deleteObject(deleteObjectRequest);
      resolve(result);
    });
    return promise;
  }

  // not support
  async preBuildConnection(serviceKey: string, bucket: string): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      Logger.error("preBuildConnection does not support")
      resolve(null);
    });
    return promise;
  }

  async getService(serviceKey: string, credentials: ESObject): Promise<void> {
    let service: CosXmlBaseService | undefined = this.getCosXmlService(serviceKey);
    let request = new ListBucketsRequest();

    if (credentials) {
      this.setRequestCredential(credentials, request);
    }

    let resultTmp: ListBucketsResult | undefined = await service?.listBucket(request);
    let result: ESObject = {};
    let buckets: BucketInfo[] = [];
    let bucketsList = resultTmp?.buckets?.buckets;

    if (bucketsList) {
      for (let i = 0; i < bucketsList.length; i++) {
        buckets[i] = bucketsList[i];
      }
    }

    result.buckets = buckets;
    result.owner = resultTmp?.buckets?.owner;
    result.marker = resultTmp?.buckets?.marker;
    result.isTruncated = resultTmp?.buckets?.isTruncated;
    result.nextMarker = resultTmp?.buckets?.nextMarker;

    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      if (result) {
        resolve(JSON.stringify(result));
      } else {
        reject(null)
      }
    });
    return promise;
  }

  async getBucket(serviceKey: string, bucket: string, region: string, prefix: string, delimiter: string,
    encodingType: string, marker: string, maxKeys: string,
    credentials: ESObject): Promise<ESObject> {
    let service: CosXmlBaseService | undefined = this.getCosXmlService(serviceKey);
    let request: ESObject;
    if (!!!prefix) {
      request = new GetBucketObjectVersionsRequest(bucket);
    } else {
      request = new ListObjectsRequest(bucket);
    }

    if (region) {
      request.region = region;
    }
    if (prefix) {
      request.prefix = prefix;
    }
    if (delimiter) {
      request.delimiter = delimiter;
    }
    if (encodingType) {
      request.encodingType = encodingType;
    }
    if (marker) {
      request.keyMarker = marker;
    }
    if (maxKeys) {
      request.maxKeys = Number(maxKeys);
    }
    this.setRequestCredential(credentials, request);

    let result: ESObject = {};
    if (!!!prefix) {
      let resultTmp: GetBucketObjectVersionsResult | undefined = await service?.getBucketObjectVersions(request);
      let result1 = resultTmp?.listVersionsResult;
      let prefixListTmp = result1?.commonPrefixes;
      let prefixList: CommonPrefixes[] = [];
      if (prefixListTmp) {
        for (let i = 0; i < prefixListTmp.length; i++) {
          prefixList[i] = prefixListTmp[i];
        }
        result.commonPrefixesList = prefixList;
      } else {
        result.commonPrefixesList = [];
      }
      if (result1?.name) {
        result.name = result1.name;
      }
      if (result1?.prefix) {
        result.prefix = result1.prefix;
      }

      if (result1?.keyMarker) {
        result.keyMarker = result1.keyMarker;
      }

      if (result1?.versionIdMarker) {
        result.versionIdMarker = result1.versionIdMarker;
      }

      if (result1?.maxKeys) {
        result.maxKeys = result1.maxKeys;
      }

      if (result1?.isTruncated) {
        result.isTruncated = result1.isTruncated;
      }

      if (result1?.delimiter) {
        result.delimiter = result1.delimiter;
      }
    } else {
      let resultTmp: ListObjectsResult | undefined = await service?.listObject(request);
      let result1 = resultTmp?.objects;
      let prefixListTmp = result1?.commonPrefixes;
      let prefixList: CommonPrefixes[] = [];
      if (prefixListTmp) {
        for (let i = 0; i < prefixListTmp.length; i++) {
          prefixList[i] = prefixListTmp[i];
        }
        result.commonPrefixesList = prefixList;
      } else {
        result.commonPrefixesList = [];
      }
      if (result1?.name) {
        result.name = result1.name;
      }
      if (result1?.prefix) {
        result.prefix = result1.prefix;
      }

      if (result1?.maxKeys) {
        result.maxKeys = result1.maxKeys;
      }

      if (result1?.isTruncated) {
        result.isTruncated = result1.isTruncated;
      }

      if (result1?.delimiter) {
        result.delimiter = result1.delimiter;
      }

      let contentsListTmp = result1?.contents;
      let contentsList: Content[] = [];
      if (contentsListTmp) {
        for (let i = 0; i < contentsListTmp.length; i++) {
          contentsList[i] = contentsListTmp[i];
          if (contentsListTmp[i].size && (typeof contentsListTmp[i].size === 'string')) {
            contentsList[i].size = Number(contentsListTmp[i].size);
          }
        }
        result.contentsList = contentsList;
      } else {
        result.contentsList = [];
      }
    }

    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      if (result) {
        resolve(JSON.stringify(result));
      } else {
        reject(null);
      }
    });
    return promise;
  }

  // not support
  async putBucket(serviceKey: string, bucket: string, region: string, enableMAZ: string, cosacl: string,
    readAccount: string, writeAccount: string, readWriteAccount: string,
    credentials: ESObject): Promise<ESObject> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      let result = '';
      resolve(result);
    });
    return promise;
  }

  async headBucket(serviceKey: string, bucket: string, region?: string, credentials?: ESObject): Promise<ESObject> {
    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      let service: CosXmlBaseService | undefined = this.getCosXmlService(serviceKey);
      let request: HeadBucketRequest = new HeadBucketRequest(bucket);
      request.credential = credentials;
      if (region) {
        request.region = region;
      }
      this.setRequestCredential(credentials, request);
      let resultTmp = await service?.headBucket(request);
      let result = resultTmp?.headers;

      resolve(result);
    });
    return promise;
  }

  // not support
  async deleteBucket(serviceKey: string, bucket: string, region?: string, credentials?: ESObject): Promise<void> {
    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async getBucketAccelerate(serviceKey: string, bucket: string, region?: string,
    credentials?: ESObject): Promise<boolean> {
    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      resolve(null)
    });
    return promise;
  }

  // not support
  async putBucketAccelerate(serviceKey: string, bucket: string, enable: boolean, region?: string,
    credentials?: ESObject): Promise<void> {
    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  // not support
  async getBucketVersioning(serviceKey: string, bucket: string, region?: string,
    credentials?: ESObject): Promise<boolean> {
    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      let service: CosXmlBaseService | undefined = this.getCosXmlService(serviceKey);
      let request: GetBucketObjectVersionsRequest = new GetBucketObjectVersionsRequest(bucket);
      request.credential = credentials;
      request.bucket = bucket;
      if (region) {
        request.region = region;
      }
      this.setRequestCredential(credentials, request);
      let result = await service?.getBucketObjectVersions(request);

      resolve(result);
    });
    return promise;
  }

  // not support
  async putBucketVersioning(serviceKey: string, bucket: string, enable: boolean, region?: string,
    credentials?: ESObject): Promise<void> {
    let promise: Promise<ESObject> = new Promise((resolve, reject) => {
      resolve(null);
    });
    return promise;
  }

  async getBucketLocation(serviceKey: string, bucket: string, region?: string,
    credentials?: ESObject): Promise<string> {
    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      let service: CosXmlBaseService | undefined = this.getCosXmlService(serviceKey);

      let region = service?.cosXmlServiceConfig?.region;
      resolve(region);
    });
    return promise;
  }

  async doesBucketExist(serviceKey: string, bucket: string): Promise<boolean> {
    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      let service: CosXmlBaseService | undefined = this.getCosXmlService(serviceKey);
      let request = new HeadBucketRequest(bucket);
      let result: HeadBucketResult | undefined = undefined;
      let flag = false;
      try {
        result = await service?.headBucket(request);
      } catch (e) {
        if (e) {
          let cosErrorCode: string = e.cosErrorCode;
          let name: string = e.name;
          if (cosErrorCode === 'CosServiceError' && name === '404') {
            flag = false;
          }
        }
      }

      if (result) {
        if (result.httpCode == 200 && result.headers) {
          flag = true;
        }
      }

      resolve(flag);
    });
    return promise;
  }

  async doesObjectExist(serviceKey: string, bucket: string, cosPath: string): Promise<boolean> {
    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      let service: CosXmlBaseService | undefined = this.getCosXmlService(serviceKey);
      let request: HeadObjectRequest = new HeadObjectRequest(bucket, cosPath);
      let result: HeadObjectResult | undefined = undefined;
      let flag = false;
      try {
        result = await service?.headObject(request);
      } catch (e) {
        if (e) {
          let cosErrorCode: string = e.cosErrorCode;
          let name: string = e.name;
          if (cosErrorCode === 'CosServiceError' && name === '404') {
            flag = false;
          }
        }
      }

      if (result) {
        if (result.httpCode == 200 && result.headers) {
          flag = true;
        }
      }
      resolve(flag);
    });
    return promise;
  }

  async cancelAll(serviceKey: string): Promise<void> {
    let service: CosXmlBaseService | undefined = this.getCosXmlService(serviceKey);
    service?.cancelAll();
    if (this.taskMap) {
      this.taskMap.clear();
    }
    let promise: Promise<ESObject> = new Promise(async (resolve, reject) => {
      resolve(null);
    });
    return promise;
  }
}