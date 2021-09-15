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

import AVFoundation
import CoreImage
import Foundation
import UIKit

import clova_see

protocol DemoInteractorProtocol: class {
    var captureSession: AVCaptureSession { get }
    func capturePhoto()
    func change(videoOrientation: AVCaptureVideoOrientation)
    func startDetecting()
    func stopDetecting()
    func switchCamera()
    func updateClovaSeeRunType(_ runType: ClovaSeeRunType)
}

class DemoInteractor: NSObject, DemoInteractorProtocol, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    
    private let cameraManager = CameraManager()
    private let detector: ClovaSeeWrapper?
    private var capturedFace: CSFace?
    private var defaultSettings: CSSettingsBuilder
    private let resourcePath = Bundle.main.path(forResource: "clovasee.all", ofType: "bundle") ?? ""
    
    private var frameCount: Int = 0
    var presenter: DemoPresenter?
    
    private var clovaSeeRunType: ClovaSeeRunType = .none
    
    override init() {
        defaultSettings = CSSettingsBuilder()
        defaultSettings.performanceMode = CSPerformanceModeType.accurate106
        detector = ClovaSeeWrapper(settings: CSSettings(builder: defaultSettings), resourcePath: resourcePath)
        
        super.init()
        
        cameraManager.prepare(self)
    }
    
    // MARK: - FaceDemoInteractorProtocol
    var captureSession: AVCaptureSession {
        return cameraManager.session
    }
    
    func capturePhoto() {
           cameraManager.capturePhoto(delegate: self)
   }
       
    func change(videoOrientation: AVCaptureVideoOrientation) {
        cameraManager.change(videoOrientation: videoOrientation)
    }
    
    func startDetecting() {
        cameraManager.startSession()
    }
    
    func stopDetecting() {
        cameraManager.stopSession()
    }
    
    func switchCamera() {
        cameraManager.switchCamera()
    }
    
    func updateClovaSeeRunType(_ runType: ClovaSeeRunType) {
        self.clovaSeeRunType = runType
    }
    
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        processClovaSeePipeline(with: pixelBuffer, runType: self.clovaSeeRunType)
        
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            guard let pixelBuffer = image.pixelBuffer(width: Int(image.size.width),
                                                      height: Int(image.size.height)) else {
                                                        return
            }
            
            detector?.processForFace(with: pixelBuffer) { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .success(let faceResult):
                    if let capturedFace = faceResult.faces.first {
                        self.presenter?.presentCapturedFrame(face: capturedFace, image: image)
                        self.capturedFace = capturedFace
                    }
                case .failure(let error):
                    print(error)
                }
            }
        } else {
            print("some error here")
        }
    }
    
}

extension DemoInteractor {
    func processClovaSeePipeline(with pixelBuffer:CVPixelBuffer, runType:ClovaSeeRunType) {
        
        let size = CGSize(width: CVPixelBufferGetWidth(pixelBuffer),
                          height: CVPixelBufferGetHeight(pixelBuffer))
        
        switch clovaSeeRunType {
        case .body:
            let elapsedTime =
                measureInMilli {
                    detector?.processForBody(with: pixelBuffer) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let bodyResult):
                            let pixels = [UInt8](bodyResult.segment.pixels)
                            guard let maskImage =
                                UIImage.fromByteArrayGray(pixels,
                                                          width: Int(size.width),
                                                          height: Int(size.height)) else {
                                                            return
                            }
                            self.presenter?.presentSegment(segment: maskImage, size: size)
                            
                        case .failure(let error):
                            self.presenter?.removeCALayer()
                            print(error)
                        }
                    }
            }
            
            if let detector = detector {
                self.presenter?.presentMeasureResult(measureResult: detector.measureResult(),
                                                     totalFPS: 1 / Float(elapsedTime))
            }
            
        case .face:
            let elapsedTime =
                measureInMilli {
                    detector?.processForFace(with: pixelBuffer) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let faceResult):
                            self.presenter?.removeCALayer()
                            self.presenter?.presentFaceInformation(faces: faceResult.faces, size: size)
                            if let capturedFace = self.capturedFace,
                                let face = faceResult.faces.first {
                                self.presenter?.presentIsSameWithCapturedFace(
                                    isSame: CSFace.isSame(withFace1: face,
                                                          face2: capturedFace),
                                    similarity: CSFace.getCosineSimilarity(withFace1: face,
                                                                           face2: capturedFace))
                            }
                            
                        case .failure(let error):
                            self.presenter?.removeCALayer()
                            print(error)
                        }
                    }
            }
            
            if let detector = detector {
                self.presenter?.presentMeasureResult(measureResult: detector.measureResult(),
                                                     totalFPS: 1 / Float(elapsedTime))
            }
            
        case .ocr:
            let elapsedTime =
                measureInMilli {
                    detector?.processForOCR(with: pixelBuffer) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let ocrResult):
                            self.presenter?.presentDocument(document: ocrResult.document, size: size)
                        case .failure(let error):
                            self.presenter?.removeCALayer()
                            print(error)
                        }
                    }
            }
            
            if let detector = detector {
                self.presenter?.presentMeasureResult(measureResult: detector.measureResult(),
                                                     totalFPS: 1 / Float(elapsedTime))
            }

            
        default:
            self.presenter?.removeCALayer()
        }
    }
}
