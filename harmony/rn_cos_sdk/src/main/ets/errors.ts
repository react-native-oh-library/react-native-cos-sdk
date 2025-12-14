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

export class IllegalArgumentError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "IllegalArgumentError";
  }
}

export class CosXmlClientError extends Error {
  public errorCode: number;
  public details?: string;
  constructor(errorCode: number, message?: string, details?: string) {
    super(message);
    this.errorCode = errorCode;
    this.details = details;

    this.name = errorCode.toString();
    // this.cause = details;
  }
}

export class CosXmlServiceError extends Error {
  public statusCode: number;
  public httpMsg?: string;
  public requestId?: string;
  public errorCode?: string;
  public errorMessage?: string;
  public serviceName?: string;
  public details?: string;

  constructor(
    statusCode: number,
    httpMsg?: string,
    requestId?: string,
    errorCode?: string,
    errorMessage?: string,
    serviceName?: string,
    details?: string,
  ) {
    super(errorMessage);
    this.statusCode = statusCode;
    this.httpMsg = httpMsg;
    this.requestId = requestId;
    this.errorCode = errorCode;
    this.errorMessage = errorMessage;
    this.serviceName = serviceName;
    this.details = details;

    if(errorCode){
      this.name = errorCode.toString();
    }
    // this.cause = details;
  }
}