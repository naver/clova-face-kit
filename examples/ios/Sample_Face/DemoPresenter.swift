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

import Foundation
import UIKit

import clova_see

protocol DemoPresenterProtocol: class {
    func presentCapturedFrame(face: CSFace, image: UIImage)
    func presentDocument(document: CSDocument, size: CGSize)
    func presentFaceInformation(faces: [CSFace], size: CGSize)
    func presentIsSameWithCapturedFace(isSame: Bool, similarity: Float)
    func presentMeasureResult(measureResult: CSMeasureResult, totalFPS: Float)
    func presentSegment(segment: UIImage, size: CGSize)
    func removeCALayer()
}

struct FaceInformation {
    let eulerAngle: String
}

class DemoPresenter: DemoPresenterProtocol {
    weak var view: DemoViewProtocol?
    
    func presentCapturedFrame(face: CSFace, image: UIImage) {
        DispatchQueue.main.async {
            self.view?.presentCapturedPhoto(face.boundingBox.rect, image: image)
        }
    }
    
    func presentDocument(document: CSDocument, size: CGSize) {
        DispatchQueue.main.async {
            self.view?.presentDocument(document, size: size)
        }
    }
    
    func presentFaceInformation(faces: [CSFace], size: CGSize) {
        DispatchQueue.main.async {
            self.view?.presentFaceInformation(faces, size: size)
        }
    }
        
    func presentIsSameWithCapturedFace(isSame: Bool, similarity: Float) {
        DispatchQueue.main.async {
            self.view?.presentIsSameWithCapturedFace(description: "\(isSame)(\(similarity))",
                                                     isSame: isSame)
        }
    }
    
    func presentMeasureResult(measureResult: CSMeasureResult, totalFPS: Float) {
        DispatchQueue.main.async {
            self.view?.presentMeasureResult(measureResult,
                                            totalFPS: String(format: "%7.1 fps", arguments: [totalFPS]))
        }
    }
    
    func presentSegment(segment: UIImage, size: CGSize) {
        DispatchQueue.main.async {
            self.view?.presentSegment(segment, size: size)
        }
    }
    
    func removeCALayer() {
        DispatchQueue.main.async {
            self.view?.removeCALayer()
        }
    }
    
}
