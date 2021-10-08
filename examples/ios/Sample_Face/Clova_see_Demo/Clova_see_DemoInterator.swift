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
import AVFoundation
import clova_see


protocol Clova_see_DemoInteratorProtocol: AnyObject {
    var captureSession: AVCaptureSession { get }

    func startDetecting()
    func switchCamera()
    func capturePhoto()
    func endChangingDetectorOption()
    func change(videoOrientation: AVCaptureVideoOrientation)
}


class Clova_see_DemoInterator: NSObject,
                               Clova_see_DemoInteratorProtocol,
                               AVCaptureVideoDataOutputSampleBufferDelegate,
                               AVCapturePhotoCaptureDelegate {
    private let cameraManager = CameraManager()
    private let detector: ClovaSeeWrapper?
    private var detectorOptionInformationType: CSStageInformationType = .all
    private var capturedFace: CSFace?
    private let serialQueue = DispatchQueue(label: "clova_see_demo")

    var presenter: Clova_see_DemoPresenterProtocol?


    override init() {
        let defaultSettings = CSSettingsBuilder()
        defaultSettings.performanceMode = CSPerformanceModeType.accurate106
        let resourcePath = Bundle.main.path(forResource: "clovasee.all", ofType: "bundle") ?? ""

        detector = ClovaSeeWrapper(settings: CSSettings(builder: defaultSettings), resourcePath: resourcePath)

        super.init()

        detectorOptionInformationType = updateDetectorOptionInformationType()
        cameraManager.prepare(self)
    }


    // MARK: - Clova_see_DemoInteratorProtocol
    var captureSession: AVCaptureSession {
        return cameraManager.session
    }

    func startDetecting() {
        cameraManager.startSession()
    }

    func switchCamera() {
        cameraManager.switchCamera()
    }

    func endChangingDetectorOption() {
        detectorOptionInformationType = updateDetectorOptionInformationType()
    }

    func change(videoOrientation: AVCaptureVideoOrientation) {
        cameraManager.change(videoOrientation: videoOrientation)
    }

    func capturePhoto() {
        cameraManager.capturePhoto(delegate: self)
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let size = CGSize(width: CVPixelBufferGetWidth(pixelBuffer),
                          height: CVPixelBufferGetHeight(pixelBuffer))

        serialQueue.async {
            self.detector?.detectFace(pixelBuffer: pixelBuffer,
                                      informationType: self.detectorOptionInformationType,
                                      completionHandler: { [weak self] (result) in
                                        guard let self = self else { return }
                                        self.presenter?.clear()
                                        switch result {
                                        case .success(let detected):
                                            self.presenter?.presentFaceInformation(faces: detected.faces, capturedFace: self.capturedFace, size: size)
                                        case .failure:
                                            break
                                        }
                                      })
        }
    }

    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {

        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            let size = image.size
            guard let pixelBuffer = image.pixelBuffer(width: Int(size.width), height: Int(size.height)) else {
                return
            }

            serialQueue.async {
                self.detector?.detectFace(pixelBuffer: pixelBuffer,
                                          informationType: self.detectorOptionInformationType,
                                          completionHandler: { [weak self] (result) in
                                            guard let self = self else { return }
                                            self.presenter?.clear()
                                            switch result {
                                            case .success(let detected):
                                                if let capturedFace = detected.faces.first {
                                                    self.capturedFace = capturedFace
                                                    self.presenter?.presentCapturedFace(face: capturedFace, image: image)
                                                }
                                            case .failure:
                                                break
                                            }
                                          })
            }
        }
    }

    private func updateDetectorOptionInformationType() -> CSStageInformationType {
        var optionFlag: Int = 0
        for key in CSUserDefaultKey.allCases {
            let available: Bool = CSUserDefault.shared.value(in: key)
            if available {
                optionFlag |= key.option.rawValue
            }
        }

        return CSStageInformationType(rawValue: UInt32(optionFlag))
    }
}


private extension CSUserDefaultKey {
    var option: CSStageType {
        switch self {
        case .availableDetector:
            return .detector
        case .availableTracker:
            return .tracker
        case .availableLandmarker:
            return .landmarker
        case .availableAligner:
            return .aligner
        case .availableRecognizer:
            return .recognizer
        case .availableEstimator:
            return .estimator
        case .availableMaskDetector:
            return .maskDetector
        case .availableSpoofingDetector:
            return .spoofingDetector
        }
    }
}
