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

#pragma once
#include "RNOH/Package.h"
#include "generated/RNOH/generated/BaseReactNativeCosSdkPackage.h"

using namespace rnoh;
using namespace facebook;

class RNCosSdkEventEmitRequestHandler : public EventEmitRequestHandler {
public:
     void handleEvent(Context const &ctx) override {
         auto eventEmitter = ctx.shadowViewRegistry->getEventEmitter<facebook::react::EventEmitter>(ctx.tag);
         if (eventEmitter == nullptr) {
             return;
         }

         std::vector<std::string> supportedEventNames = {
            "COSEmitterUpdateSessionCredential", "COSEmitterDnsFetch", "COSEmitterResultSuccessCallback", "COSEmitterResultFailCallback", "COSEmitterProgressCallback", "COSEmitterStateCallback", "COSEmitterInitMultipleUploadCallback", "COSEmitterUpdateClsSessionCredential", "COSEmitterLogCallback"
         };
         if (std::find(supportedEventNames.begin(), supportedEventNames.end(), ctx.eventName) !=
             supportedEventNames.end()) {
             eventEmitter->dispatchEvent(ctx.eventName, ArkJS(ctx.env).getDynamic(ctx.payload));
         }
     }
};

namespace rnoh {
class RNCosSdkPackage : public BaseReactNativeCosSdkPackage {
    using Super = BaseReactNativeCosSdkPackage;
    
public:
    RNCosSdkPackage(Package::Context ctx) : Super(ctx) {}

    EventEmitRequestHandlers createEventEmitRequestHandlers() override {
        return {std::make_shared<RNCosSdkEventEmitRequestHandler>()};
    };
};
} // namespace rnoh
