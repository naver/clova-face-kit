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

import Accelerate
import AVFoundation
import UIKit

extension CVPixelBuffer {
    func convertBGRA8888toRGB888() -> CVPixelBuffer? {
        let flags = CVPixelBufferLockFlags(rawValue: 0)
        guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(self, flags) else { return nil }
        
        defer { CVPixelBufferUnlockBaseAddress(self, flags) }
        guard let sourceData = CVPixelBufferGetBaseAddress(self) else {
            assert(false, "Failed to get pixel buffer base address")
            return nil
        }
        
        let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(self)
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        
        var sourceBuffer = vImage_Buffer(data: sourceData,
                                         height: vImagePixelCount(height),
                                         width: vImagePixelCount(width),
                                         rowBytes: sourceBytesPerRow)
        
        let destinationBytesPerRow = width * 3
        guard let destinationData = malloc(height * destinationBytesPerRow) else {
            assert(false, "Failed to allocate memory")
            return nil
        }
        
        var destinationBuffer = vImage_Buffer(data: destinationData,
                                              height: vImagePixelCount(height),
                                              width: vImagePixelCount(width),
                                              rowBytes: destinationBytesPerRow)
        
        let error = vImageConvert_BGRA8888toRGB888(&sourceBuffer,
                                                   &destinationBuffer,
                                                   vImage_Flags(kvImageLeaveAlphaUnchanged))
        
        if error != kvImageNoError {
            assert(false, "Error : \(error)")
            free(destinationData)
            
            return nil
        }
        
        let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
            if let ptr = ptr {
                free(UnsafeMutableRawPointer(mutating: ptr))
            }
        }
        
        var destPixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreateWithBytes(nil, width, height, kCVPixelFormatType_24RGB,
                                                  destinationData, destinationBytesPerRow, releaseCallback,
                                                  nil, nil, &destPixelBuffer)
        
        if status != kCVReturnSuccess {
            assert(false, "Failed to create new pixel buffer")
            free(destinationData)
            return nil
        }
        
        return destPixelBuffer
    }
    
}
