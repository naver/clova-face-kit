// CLOVA Face Kit
// Copyright (c) 2021-present NAVER Corp.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import clova_see

extension ClovaSeeWrapper {
    func detectFace(pixelBuffer: CVPixelBuffer, informationType: CSStageInformationType, completionHandler: @escaping (Result<CSFaceResult, Error>) -> Void) {
        guard let rgbPixelBuffer = pixelBuffer.convertBGRA8888toRGB888() else {
            completionHandler(.failure(ClovaSeeError.noPixelBuffer))
            return
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        CVPixelBufferLockBaseAddress(rgbPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        defer {
            CVPixelBufferUnlockBaseAddress(rgbPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        }

        guard let rgbDataPointer = CVPixelBufferGetBaseAddress(rgbPixelBuffer) else {
            completionHandler(.failure(ClovaSeeError.noPixelBuffer))
            return
        }

        let frame = CSFrame(pixels: rgbDataPointer,
                            width: CGFloat(width),
                            height: CGFloat(height),
                            type: CSFrameFormatType.RGB888)

        // TODO(@youngsoo.lee) : expose options to the UI
        let options = CSFaceOptionsBuilder()
        options.informationType = informationType.rawValue
        options.minimumBoundingBoxSize = 0.1
        let result = self.runForFace(with: frame, options: CSFaceOptions(builder: options))

        completionHandler(.success(result))

    }
}
