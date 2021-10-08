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
import clova_see

protocol Clova_see_DemoPresenterProtocol: AnyObject {
    func clear()
    func presentCapturedFace(face: CSFace, image: UIImage)
    func presentFaceInformation(faces: [CSFace], capturedFace: CSFace?, size: CGSize)
}


class Clova_see_DemoPresenter: Clova_see_DemoPresenterProtocol {
    weak var view: Clova_see_DemoViewProtocol?

    // MARK: - Clova_see_DemoPresenterProtocol
    func clear() {
        DispatchQueue.main.async {
            self.view?.clear()
        }
    }

    func presentCapturedFace(face: CSFace, image: UIImage) {
        guard let croppedFaceImage = image.cropped(rect: face.boundingBox.rect) else { return }
        DispatchQueue.main.async {
            self.view?.drawCapturesFace(image: croppedFaceImage)
        }
    }

    func presentFaceInformation(faces: [CSFace], capturedFace: CSFace?, size: CGSize) {
        DispatchQueue.main.async {
            for face in faces {
                self.presentContour(face: face, size: size)
                self.presentEulerAngle(face: face, size: size)
                self.presentMaskDetectionResult(face: face, size: size)
                self.presentSpoofingDetectionResult(face: face, size: size)

                if let capturedFace = capturedFace {
                    self.view?.drawSimilarity(similarity: CSFace.getCosineSimilarity(withFace1: face, face2: capturedFace))
                }
            }
        }
    }

    private func presentContour(face: CSFace, size: CGSize) {
        guard let typeCasted = face.contour.points as? [NSValue] else { return }
        let points = typeCasted.map { $0.cgPointValue }
        self.view?.drawContour(points: points, size: size)
    }

    private func presentEulerAngle(face: CSFace, size: CGSize) {
        let description = String(format: "[x: %4.2f, y: %4.2f, z: %4.2f]",
                                 arguments: [face.eulerAngle.x,
                                             face.eulerAngle.y,
                                             face.eulerAngle.z])

        self.view?.drawEulerAngle(eulerAngleDescription: description,
                                  faceBoundingRect: face.boundingBox.rect,
                                  size: size)
    }

    private func presentMaskDetectionResult(face: CSFace, size: CGSize) {
        self.view?.drawMaskDetectionResult(isMasked: face.mask, faceBoundingRect: face.boundingBox.rect, size: size)
    }

    private func presentSpoofingDetectionResult(face: CSFace, size: CGSize) {
        self.view?.drawSpoofingDetectionResult(isSpoofed: face.spoof, faceBoundingRect: face.boundingBox.rect, size: size)
    }
}
