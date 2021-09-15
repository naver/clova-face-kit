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

import Accelerate
import AVFoundation
import Foundation
import UIKit


func clamp<T: Comparable>(value: T, lower: T, upper: T) -> T {
    return min(max(value, lower), upper)
    
    
}

func resizePixelBuffer(_ srcPixelBuffer: CVPixelBuffer, factor: UInt8) -> CVPixelBuffer? {
    CVPixelBufferLockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    
    defer {
        CVPixelBufferUnlockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
    guard let srcData = CVPixelBufferGetBaseAddress(srcPixelBuffer) else {
        print("Error: could not get pixel buffer base address")
        return nil
    }
    
    let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer)
    let srcWidth = CVPixelBufferGetWidth(srcPixelBuffer)
    let srcHeight = CVPixelBufferGetHeight(srcPixelBuffer)
    
    let destWidth = srcWidth / Int(factor)
    let destHeight = srcHeight / Int(factor)
    
    let destBytesPerRow = destWidth * 4
    
    var srcBuffer = vImage_Buffer(data: srcData,
                                  height: vImagePixelCount(srcHeight),
                                  width: vImagePixelCount(srcWidth),
                                  rowBytes: srcBytesPerRow)
    
    guard let destData = malloc(destBytesPerRow * destHeight * MemoryLayout<UInt8>.size) else {
        print("Error: out of memory")
        return nil
    }
    
    var destBuffer = vImage_Buffer(data: destData,
                                   height: vImagePixelCount(destHeight),
                                   width: vImagePixelCount(destWidth),
                                   rowBytes: destBytesPerRow)
    
    let error = vImageScale_ARGB8888(&srcBuffer, &destBuffer, nil, vImage_Flags(0))
    
    if error != kvImageNoError {
        print("Error : \(error)")
        free(destData)
        
        return nil
    }
    
    let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
        if let ptr = ptr {
            free(UnsafeMutableRawPointer(mutating: ptr))
        }
    }
    
    let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
    var dstPixelbuffer: CVPixelBuffer?
    let status = CVPixelBufferCreateWithBytes(nil, destWidth, destHeight, pixelFormat, destData, destBytesPerRow, releaseCallback, nil, nil, &dstPixelbuffer)
    
    if status != kCVReturnSuccess {
        print("Error: could not create new pixel buffer")
        free(destData)
        
        return nil
    }
    
    return dstPixelbuffer
    
}

func rotate90PixelBuffer(_ srcPixelBuffer: CVPixelBuffer, factor: UInt8) -> CVPixelBuffer? {
    CVPixelBufferLockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    guard let srcData = CVPixelBufferGetBaseAddress(srcPixelBuffer) else {
        print("Error: could not get pixel buffer base address")
        return nil
    }
    let sourceWidth = CVPixelBufferGetWidth(srcPixelBuffer)
    let sourceHeight = CVPixelBufferGetHeight(srcPixelBuffer)
    var destWidth = sourceHeight
    var destHeight = sourceWidth
    var color = UInt8(0)
    
    if factor % 2 == 0 {
        destWidth = sourceWidth
        destHeight = sourceHeight
    }
    
    let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer)
    var srcBuffer = vImage_Buffer(data: srcData,
                                  height: vImagePixelCount(sourceHeight),
                                  width: vImagePixelCount(sourceWidth),
                                  rowBytes: srcBytesPerRow)
    
    let destBytesPerRow = destWidth*4
    guard let destData = malloc(destHeight*destBytesPerRow) else {
        print("Error: out of memory")
        return nil
    }
    var destBuffer = vImage_Buffer(data: destData,
                                   height: vImagePixelCount(destHeight),
                                   width: vImagePixelCount(destWidth),
                                   rowBytes: destBytesPerRow)
    
    let error = vImageRotate90_ARGB8888(&srcBuffer, &destBuffer, factor, &color, vImage_Flags(0))
    
    CVPixelBufferUnlockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    if error != kvImageNoError {
        print("Error:", error)
        free(destData)
        return nil
    }
    
    let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
        if let ptr = ptr {
            free(UnsafeMutableRawPointer(mutating: ptr))
        }
    }
    
    let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
    var dstPixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreateWithBytes(nil, destWidth, destHeight,
                                              pixelFormat, destData,
                                              destBytesPerRow, releaseCallback,
                                              nil, nil, &dstPixelBuffer)
    if status != kCVReturnSuccess {
        print("Error: could not create new pixel buffer")
        free(destData)
        return nil
    }
    return dstPixelBuffer
}
