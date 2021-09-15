// CLOVA SEE
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

import AVFoundation

import clova_see

enum ClovaSeeError: Error {
    case noPixelBuffer
    case noHuman
}


extension ClovaSeeWrapper {
    func processForBody(with pixelBuffer: CVPixelBuffer, completionHandler: @escaping (Result<CSBodyResult, Error>) -> Void) {
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
            return
        }
        
        let frame = CSFrame(pixels: rgbDataPointer,
                            width: CGFloat(width),
                            height: CGFloat(height),
                            type: CSFrameFormatType.RGB888)
        
        // TODO(@youngsoo.lee) : expose options to the UI
        let result = self.runForBody(with: frame, options: CSBodyOptions())
        
        completionHandler(.success(result))
    }
    
    func processForFace(with pixelBuffer: CVPixelBuffer, completionHandler: @escaping (Result<CSFaceResult, Error>) -> Void) {
        
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
            return
        }
        
        let frame = CSFrame(pixels: rgbDataPointer,
                            width: CGFloat(width),
                            height: CGFloat(height),
                            type: CSFrameFormatType.RGB888)
        
        // TODO(@youngsoo.lee) : expose options to the UI
        let options = CSFaceOptionsBuilder()
        options.informationType = CSStageInformationType.contours.rawValue |
                                  CSStageInformationType.masks.rawValue |
                                  CSStageInformationType.eulerAngles.rawValue
        options.minimumBoundingBoxSize = 0.1
        let result = self.runForFace(with: frame, options: CSFaceOptions(builder: options))
        
        completionHandler(.success(result))

    }
    
    func processForOCR(with pixelBuffer: CVPixelBuffer, completionHandler: @escaping (Result<CSOcrResult, Error>) -> Void) {
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
            return
        }
        
        let frame = CSFrame(pixels: rgbDataPointer,
                            width: CGFloat(width),
                            height: CGFloat(height),
                            type: CSFrameFormatType.RGB888)
        
        // TODO(@youngsoo.lee) : expose options to the UI
        let result = self.runForOcr(with: frame, options: CSOcrOptions())
        
        completionHandler(.success(result))
        
    }
    
}
