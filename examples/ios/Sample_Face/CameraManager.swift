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
import UIKit

class CameraManager {
    private var devicePosition: AVCaptureDevice.Position
    private let videoDataOutputQueue = DispatchQueue(label: "ai.clova.see.example.videoOutput")
    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var photoOutput: AVCapturePhotoOutput!
    private var videoConnection: AVCaptureConnection? {
        return videoDataOutput.connection(with: .video)
    }
    private var photoConnection: AVCaptureConnection? {
        return photoOutput.connection(with: .video)
    }
    private let isMirroredFrontCamera: Bool
    
    let session = AVCaptureSession()
    
    init(devicePosition: AVCaptureDevice.Position = .front, isMirroredFrontCamera: Bool = true) {
        self.devicePosition = devicePosition
        self.isMirroredFrontCamera = isMirroredFrontCamera
    }
    
    func prepare(_ sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate & AVCapturePhotoCaptureDelegate) {
        DispatchQueue.global().async {
            self.prepareSession()
            self.prepareOutput(sampleBufferDelegate)
            self.updateCameraMirrored(devicePosition: self.devicePosition)
        }
    }
    
    private func prepareSession() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: devicePosition) else { return }
        session.sessionPreset = AVCaptureSession.Preset.hd1280x720
        do {
            let deviceInput = try AVCaptureDeviceInput(device: camera)
            session.beginConfiguration()
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            session.commitConfiguration()
        } catch {
            print("error with creating AVCaptureDeviceInput")
        }
    }
    
    private func prepareOutput(_ sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        self.videoDataOutput = AVCaptureVideoDataOutput()
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32BGRA)]
        if session.canAddOutput(self.videoDataOutput) {
            self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
            session.addOutput(self.videoDataOutput)
            self.videoConnection?.videoOrientation = .portrait
            self.videoDataOutput.setSampleBufferDelegate(sampleBufferDelegate, queue: videoDataOutputQueue)
        }
        
        self.photoOutput = AVCapturePhotoOutput()
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            self.photoConnection?.videoOrientation = .portrait
            self.photoOutput.isHighResolutionCaptureEnabled = true
        }
    }
    
    private func updateCameraMirrored(devicePosition: AVCaptureDevice.Position) {
        if isMirroredFrontCamera == false && devicePosition == .front {
            self.videoConnection?.isVideoMirrored = false
            self.photoConnection?.isVideoMirrored = false
        } else {
            self.videoConnection?.isVideoMirrored = self.devicePosition == .front
            self.photoConnection?.isVideoMirrored = self.devicePosition == .front
        }
    }
    
    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
        self.photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: delegate)
    }
    
    private func findDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                mediaType: AVMediaType.video,
                                                                position: .unspecified)
        for device in discoverySession.devices where device.position == position {
            return device
        }
        return nil
    }
    
    func switchCamera() {
        let videoOrientation = self.videoConnection!.videoOrientation
        DispatchQueue.global().async {
            self.stopSession()
            self.session.beginConfiguration()
            
            guard let currentCameraInput: AVCaptureInput = self.session.inputs.first else { return }
            self.session.removeInput(currentCameraInput)
            
            var newCamera: AVCaptureDevice! = nil
            if let input = currentCameraInput as? AVCaptureDeviceInput {
                newCamera = self.findDevice(position: input.device.position == .back ? .front : .back)
            }
            
            let newVideoInput: AVCaptureDeviceInput = (try? AVCaptureDeviceInput(device: newCamera))!
            if self.session.canAddInput(newVideoInput) {
                self.session.addInput(newVideoInput)
            }
            
            self.devicePosition = newCamera.position
            self.videoConnection?.videoOrientation = videoOrientation
            self.photoConnection?.videoOrientation = videoOrientation
            self.updateCameraMirrored(devicePosition: self.devicePosition)
            
            self.session.commitConfiguration()
            self.startSession()
        }
    }
    
    func change(videoOrientation: AVCaptureVideoOrientation) {
        self.videoConnection?.videoOrientation = videoOrientation
        self.photoConnection?.videoOrientation = videoOrientation
    }
    
    func startSession() {
        guard !self.session.isRunning else { return }
        self.session.startRunning()
    }
    
    func stopSession() {
        guard self.session.isRunning else { return }
        self.session.stopRunning()
    }
}
