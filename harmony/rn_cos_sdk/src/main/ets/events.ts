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

import type { CosXmlClientError, CosXmlServiceError } from "./errors";

// native to js: 更新临时秘钥
export const COS_EMITTER_UPDATE_SESSION_CREDENTIAL: string = "COSEmitterUpdateSessionCredential"
// native to js: 获取domain对应的ip数组
export const COS_EMITTER_DNS_FETCH: string = "COSEmitterDnsFetch"
// native to js: 回调结果成功
export const COS_EMITTER_RESULT_SUCCESS_CALLBACK: string = "COSEmitterResultSuccessCallback";
// native to js: 回调结果失败
export const COS_EMITTER_RESULT_FAIL_CALLBACK: string = "COSEmitterResultFailCallback";
// native to js: 回调进度
export const COS_EMITTER_PROGRESS_CALLBACK: string = "COSEmitterProgressCallback";
// native to js: 回调状态
export const COS_EMITTER_STATE_CALLBACK: string = "COSEmitterStateCallback";
// native to js: 回调分块上传初始化
export const COS_EMITTER_INIT_MULTIPLE_UPLOAD_CALLBACK: string = "COSEmitterInitMultipleUploadCallback";

// native to js: 更新CLS临时秘钥
export const COS_EMITTER_UPDATE_CLS_SESSION_CREDENTIAL: string = "COSEmitterUpdateClsSessionCredential"
// native to js: 日志回调
export const COS_EMITTER_LOG_CALLBACK: string = "COSEmitterLogCallback"

export type UpdateSessionCredentialEvent = {
    stsScopesArrayJson?: string;
}

export type TransferResultSuccessEvent = {
    transferKey: string;
    callbackKey: string;
    headers?: object;
}

export type TransferResultFailEvent = {
    transferKey: string;
    callbackKey: string;
    clientException?: CosXmlClientError;
    serviceException?: CosXmlServiceError;
}

export type TransferProgressEvent = {
    transferKey: string;
    callbackKey: string;
    complete: string;
    target: string;
}

export type TransferStateEvent = {
    transferKey: string;
    callbackKey: string;
    state: string;
}

export type InitMultipleUploadEvent = {
    transferKey: string;
    callbackKey: string;
    bucket: string;
    key: string;
    uploadId: string;
}

export type LogEvent = {
    key: string;
    logEntityJson: string;
}