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
import UIKit

extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return .portrait
        }
    }
}

public extension CGPoint {
    enum AspectType {
        case fill
        case fit
    }

    func changeScale(to targetSize: CGSize, parentScreenSize: CGSize, aspectType: AspectType = .fill) -> CGPoint {
        let aspectRatioOfImage = targetSize.width / targetSize.height
        let aspectRatioOfParent = parentScreenSize.width / parentScreenSize.height

        let aspectRatio: CGFloat
        let isFittedVertically: Bool

        let isScaledToVertically: Bool
        if aspectType == .fill {
            isScaledToVertically = aspectRatioOfImage > aspectRatioOfParent
        } else {
            isScaledToVertically = aspectRatioOfImage < aspectRatioOfParent
        }

        if isScaledToVertically {
            aspectRatio = targetSize.width / parentScreenSize.width
            isFittedVertically = false
        } else {
            aspectRatio = targetSize.height / parentScreenSize.height
            isFittedVertically = true
        }

        let weightSize = CGSize(width: parentScreenSize.width * aspectRatio, height: parentScreenSize.height * aspectRatio)

        let x: CGFloat
        let y: CGFloat

        if isFittedVertically {
            x = self.x * aspectRatio + (targetSize.width - weightSize.width) / 2
            y = self.y * aspectRatio
        } else {
            x = self.x * aspectRatio
            y = self.y * aspectRatio + (targetSize.height - weightSize.height) / 2
        }

        return CGPoint(x: x, y: y)
    }
}

public extension CGRect {
    enum AspectType {
        case fill
        case fit
    }

    func changeScale(to targetSize: CGSize, parentScreenSize: CGSize, aspectType: AspectType = .fill) -> CGRect {
        let aspectRatioOfImage = targetSize.width / targetSize.height
        let aspectRatioOfParent = parentScreenSize.width / parentScreenSize.height

        let aspectRatio: CGFloat
        let isFittedVertically: Bool

        let isScaledToVertically: Bool
        if aspectType == .fill {
            isScaledToVertically = aspectRatioOfImage > aspectRatioOfParent
        } else {
            isScaledToVertically = aspectRatioOfImage < aspectRatioOfParent
        }

        if isScaledToVertically {
            aspectRatio = targetSize.width / parentScreenSize.width
            isFittedVertically = false
        } else {
            aspectRatio = targetSize.height / parentScreenSize.height
            isFittedVertically = true
        }

        let weightSize = CGSize(width: parentScreenSize.width * aspectRatio, height: parentScreenSize.height * aspectRatio)

        let x: CGFloat
        let y: CGFloat

        if isFittedVertically {
            x = origin.x * aspectRatio + (targetSize.width - weightSize.width) / 2
            y = origin.y * aspectRatio
        } else {
            x = origin.x * aspectRatio
            y = origin.y * aspectRatio + (targetSize.height - weightSize.height) / 2
        }

        return CGRect(x: x, y: y, width: size.width * aspectRatio, height: size.height * aspectRatio)
    }
}

struct ClovaSeeRunType: OptionSet {
    let rawValue: Int
    
    static let body = ClovaSeeRunType(rawValue: 1 << 0)
    static let face = ClovaSeeRunType(rawValue: 1 << 1)
    static let ocr = ClovaSeeRunType(rawValue: 1 << 2)
    
    static let none: ClovaSeeRunType = []
    static let bodyAndFace: ClovaSeeRunType = [.body, .face]
    static let faceAndOcr: ClovaSeeRunType = [.face, .ocr]
    static let all: ClovaSeeRunType = [.body, .face, .ocr]
}


func measureInMilli(block : (() -> Void)) -> Double {
    let start = CFAbsoluteTimeGetCurrent()
    block()
    let end = CFAbsoluteTimeGetCurrent()
    
    return end - start
}
