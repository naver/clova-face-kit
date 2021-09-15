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

import clova_see

protocol DemoViewProtocol: class {
    func presentCapturedPhoto(_ rect: CGRect, image: UIImage)
    func presentDocument(_ document: CSDocument, size: CGSize)
    func presentFaceInformation(_ faces: [CSFace], size: CGSize)
    func presentIsSameWithCapturedFace(description: String, isSame: Bool)
    func presentMeasureResult(_ measureResult: CSMeasureResult, totalFPS: String)
    func presentSegment(_ segment: UIImage, size: CGSize)
    func removeCALayer()
}

class ViewController: UIViewController, DemoViewProtocol {
    @IBOutlet weak var performanceInMillis: UILabel!
    @IBOutlet weak var nativeInMillis: UILabel!
    @IBOutlet weak var alingerInMillis: UILabel!
    @IBOutlet weak var detectorInMillis: UILabel!
    @IBOutlet weak var estimatorInMillis: UILabel!
    @IBOutlet weak var landmarkerInMillis: UILabel!
    @IBOutlet weak var recognizerInMillis: UILabel!
    @IBOutlet weak var trackerInMillis: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var informationView: UIView!
    @IBOutlet weak var isSameLabel: UILabel!
    @IBOutlet weak var shootButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var bodyModeButton: UIButton! {
        didSet {
            bodyModeButton.setBackgroundColor(.yellow, for: .selected)
            bodyModeButton.setBackgroundColor(.gray, for: .disabled)
        }
    }
    @IBOutlet weak var faceModeButton: UIButton! {
        didSet {
            faceModeButton.setBackgroundColor(.yellow, for: .selected)
            faceModeButton.setBackgroundColor(.gray, for: .disabled)
        }
    }
    @IBOutlet weak var ocrModeButton: UIButton! {
        didSet {
            ocrModeButton.setBackgroundColor(.yellow, for: .selected)
            ocrModeButton.setBackgroundColor(.gray, for: .disabled)
        }
    }
    @IBOutlet weak var capturedImageView: UIImageView!
    
    private static let greenColor = UIColor.init(red: 0, green: 199 / 255, blue: 60 / 255, alpha: 1)
    private static let redColor = UIColor.init(red: 200 / 255, green: 0, blue: 10 / 255, alpha: 1)
    
    var clovaSeeRunType: ClovaSeeRunType = .face
    
    var interactor: DemoInteractorProtocol?
    
    var faceFrameLayer: CALayer = {
        let layer = CALayer()
        layer.borderColor = ViewController.redColor.cgColor
        layer.borderWidth = 1
        layer.drawsAsynchronously = true
        layer.shouldRasterize = true
        return layer
    }()
    
    var landmarkFrameLayer: CALayer = {
        let layer = CALayer()
        layer.borderColor = ViewController.greenColor.cgColor
        layer.borderWidth = 1
        layer.drawsAsynchronously = true
        layer.shouldRasterize = true
        return layer
    }()
    
    var headPoselabelView: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = .clear
        return view
    }()
    
    var heatmapFrameLayer: CALayer = {
        let layer = CALayer()
        layer.borderWidth = 1
        layer.drawsAsynchronously = true
        layer.shouldRasterize = true
        layer.contentsGravity = .resizeAspectFill
        return layer
    }()
    
    var masklabelView: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = .clear
        return view
    }()
    
    var liveneseeLayer: CALayer = {
        let layer = CALayer()
        layer.drawsAsynchronously = true
        layer.shouldRasterize = true
        return layer
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
        guard let session = interactor?.captureSession else { return nil }
        var previewLay = AVCaptureVideoPreviewLayer(session: session)
        previewLay.videoGravity = .resizeAspectFill
        return previewLay
        
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        previewLayer?.frame = view.frame
        guard let previewLayer = previewLayer else { return }
        cameraView.layer.addSublayer(previewLayer)
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in },
        completion: { [weak self] (_) in
            guard let self = self, let previewLayer = self.previewLayer else { return }
            let videoOrientation = UIApplication.shared.statusBarOrientation.videoOrientation
            previewLayer.connection?.videoOrientation = videoOrientation
            previewLayer.frame.size = self.view.frame.size
            self.interactor?.change(videoOrientation: videoOrientation)
        })
    }
    
    // MARK: - TouchEvent
    @IBAction func switchCameraTouched(_ sender: Any) {
        faceFrameLayer.removeFromSuperlayer()
        landmarkFrameLayer.removeFromSuperlayer()
        interactor?.switchCamera()
    }
    
    @IBAction func didClickShootButton(_ sender: Any) {
        interactor?.capturePhoto()
    }
    
    @IBAction func didClickStartButton(_ sender: Any) {
        (sender as! UIButton).isSelected = !(sender as! UIButton).isSelected
        if (sender as! UIButton).isSelected {
            interactor?.startDetecting()
        } else {
            interactor?.stopDetecting()
        }
    }
    
    @IBAction func didClickRemoveButton(_ sender: Any) {
        self.removeCALayer()
    }
    
    // TODOs(@youngsoo.lee) : support multi options.
    @IBAction func didClickFaceButton(_ sender: Any) {
        (sender as! UIButton).isSelected = !(sender as! UIButton).isSelected
        if (sender as! UIButton).isSelected {
            clovaSeeRunType = .face
            self.bodyModeButton.isSelected = false
            self.ocrModeButton.isSelected = false
        } else {
            clovaSeeRunType = .none
        }
        self.interactor?.updateClovaSeeRunType(self.clovaSeeRunType)
    }
    
    @IBAction func didClickBodyButton(_ sender: Any) {
        (sender as! UIButton).isSelected = !(sender as! UIButton).isSelected
        if (sender as! UIButton).isSelected {
            clovaSeeRunType = .body
            self.faceModeButton.isSelected = false
            self.ocrModeButton.isSelected = false
        } else {
            clovaSeeRunType = .none
        }
        self.interactor?.updateClovaSeeRunType(self.clovaSeeRunType)
    }
    
    @IBAction func didClickOCRButton(_ sender: Any) {
        (sender as! UIButton).isSelected = !(sender as! UIButton).isSelected
        if (sender as! UIButton).isSelected {
            clovaSeeRunType = .ocr
            self.bodyModeButton.isSelected = false
            self.faceModeButton.isSelected = false
        } else {
            clovaSeeRunType = .none
        }
        self.interactor?.updateClovaSeeRunType(self.clovaSeeRunType)
    }
    
    // MARK: - FaceDemoViewProtocol
    func presentFaceInformation(_ faces: [CSFace], size: CGSize) {
        self.clearView()
        for face in faces {
            drawBoundingBoxWithMask(face: face, size: size)
            drawContour(face: face, size: size)
            drawEulerAngle(face: face, size: size)
            drawSpoof(face: face, size: size)
        }
    }
    
    func presentDocument(_ document: CSDocument, size: CGSize) {
        self.clearView()
        if (!document.clockwisePoints.isEmpty) {
            drawPolygon(document: document, size: size)
        }
    }
    
    
    func presentIsSameWithCapturedFace(description: String, isSame: Bool) {
        self.isSameLabel.text = description
        if self.capturedImageView.image == nil {
            self.faceFrameLayer.borderColor = ViewController.greenColor.cgColor
        } else {
            self.faceFrameLayer.borderColor = (isSame ? ViewController.greenColor : ViewController.redColor).cgColor
        }
    }
    
    func presentMeasureResult(_ measureResult: CSMeasureResult, totalFPS: String) {
        self.performanceInMillis.text = totalFPS
        self.nativeInMillis.text = String(format: "%3.1f fps", arguments: [measureResult.totalFPS])
        self.alingerInMillis.text = String(format: "%3.1f ms", arguments: [measureResult.alignerInMilli])
        self.detectorInMillis.text = String(format: "%3.1f ms", arguments: [measureResult.detectorInMilli])
        self.estimatorInMillis.text = String(format: "%3.1f ms", arguments: [measureResult.estimatorInMilli])
        self.landmarkerInMillis.text = String(format: "%3.1f ms", arguments: [measureResult.landmarkInMilli])
        self.recognizerInMillis.text = String(format: "%3.1f ms", arguments: [measureResult.recognizerInMilli])
        self.trackerInMillis.text = String(format: "%3.1f ms", arguments: [measureResult.trackerInMilli])
    }
    
    func presentSegment(_ segment: UIImage, size: CGSize) {
        clearView()
        drawSegment(segment: segment, size: size)
    }
    
    func removeCALayer() {
        clearView()
    }
    
    func presentCapturedPhoto(_ rect: CGRect, image: UIImage) {
        self.capturedImageView.image = image.cropped(rect: rect)
    }
    
    func clearView() {
        self.faceFrameLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.faceFrameLayer.removeFromSuperlayer()
        self.heatmapFrameLayer.sublayers?.forEach { $0.removeFromSuperlayer()}
        self.heatmapFrameLayer.removeFromSuperlayer()
        self.headPoselabelView.subviews.forEach { $0.removeFromSuperview() }
        self.landmarkFrameLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.landmarkFrameLayer.removeFromSuperlayer()
        self.liveneseeLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.masklabelView.subviews.forEach { $0.removeFromSuperview() }
    }
    
}

extension ViewController {
    // MARK: - Draw Face function
    func drawBoundingBoxWithMask(face: CSFace, size: CGSize) {
        let preferredSize = self.view.frame.size
        
        let rect = face.boundingBox.rect.changeScale(to: preferredSize,
                                                     parentScreenSize: size)
        
        drawRect(rect: rect, isFillRect: face.mask, targetLayer: self.faceFrameLayer)
        let frame = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width / 2, height: 20)
        let maskDescription = face.mask ? "Mask ON" : "Mask OFF"
        drawText(text: maskDescription, frame: frame, targetView: self.masklabelView)
        
        self.view.layer.addSublayer(self.faceFrameLayer)
        self.view.addSubview(self.masklabelView)
    }
    
    func drawContour(face: CSFace, size: CGSize) {
        let preferredSize = self.view.frame.size
        let points = (face.contour.points as! [NSValue]).map {
            (value : NSValue) -> CGPoint in
            let point = value.cgPointValue
            return point.changeScale(to: preferredSize, parentScreenSize: size)
        }
        drawPoints(points: points, targetView: self.landmarkFrameLayer)

        self.view.layer.addSublayer(self.landmarkFrameLayer)
    }
    
    func drawEulerAngle(face: CSFace, size: CGSize) {
        let preferredSize = self.view.frame.size
        let rect = face.boundingBox.rect.changeScale(to: preferredSize, parentScreenSize: size)
        let frame = CGRect(x: rect.origin.x,
                           y: rect.origin.y - 20,
                           width: rect.width,
                           height: 20)
        let angleDescription = String(format: "[x: %4.2f, y: %4.2f, z: %4.2f]",
                                      arguments: [face.eulerAngle.x,
                                                  face.eulerAngle.y,
                                                  face.eulerAngle.z])
        
        drawText(text: angleDescription, frame: frame, targetView: self.headPoselabelView)
    
        self.view.addSubview(self.headPoselabelView)
    }
    
    func drawPolygon(document: CSDocument, size: CGSize) {
        let preferredSize = self.view.frame.size
        let points = (document.clockwisePoints as! [NSValue]).map {
            (value : NSValue) -> CGPoint in
            let point = value.cgPointValue
            return point.changeScale(to: preferredSize, parentScreenSize: size)
        }
        drawPoints(points: points, targetView: self.landmarkFrameLayer, pointSize: 10)

        self.view.layer.addSublayer(self.landmarkFrameLayer)
    }
    
    func drawSegment(segment: UIImage, size: CGSize) {        
        guard let cgImage = segment.cgImage else {
            return
        }
        self.heatmapFrameLayer.frame = self.view.frame
        self.heatmapFrameLayer.contents = cgImage
        self.heatmapFrameLayer.opacity = 0.7
        self.view.layer.addSublayer(self.heatmapFrameLayer)
    }
    
    func drawSpoof(face: CSFace, size: CGSize) {
        let preferredSize = self.view.frame.size
        
        if (face.spoof) {
            let rect = face.boundingBox.rect.changeScale(to: preferredSize, parentScreenSize: size)
            let left = rect.origin.x
            let top = rect.origin.y
            let right = rect.origin.x + rect.size.width
            let bottom = rect.origin.y + rect.size.height
            
            drawLine(fromPointA: CGPoint(x: left, y: top), toPointB: CGPoint(x: right, y: bottom), targetView: self.liveneseeLayer)
            drawLine(fromPointA: CGPoint(x: right, y: top), toPointB: CGPoint(x: left, y: bottom), targetView: self.liveneseeLayer)
        }
        self.view.layer.addSublayer(self.liveneseeLayer)
    }
    
}

extension ViewController {
    // MARK: - Draw function
    func drawPoints(points: [CGPoint], targetView: CALayer, pointSize: Int = 3) {
        let layer = CALayer()
        layer.frame = self.view.frame
        for value in points {
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = UIBezierPath(ovalIn: CGRect(origin: value,
                                                          size: CGSize(width: pointSize,
                                                                       height: pointSize))).cgPath
            shapeLayer.fillColor = ViewController.greenColor.cgColor
            layer.addSublayer(shapeLayer)
        }
        targetView.addSublayer(layer)
    }
    
    func drawLine(fromPointA: CGPoint, toPointB: CGPoint, targetView: CALayer) {
        let layer = CALayer()
        layer.frame = self.view.frame
        
        let lineLayer = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: fromPointA)
        linePath.addLine(to: toPointB)
        lineLayer.path = linePath.cgPath
        lineLayer.fillColor = nil
        lineLayer.opacity = 1.0
        lineLayer.strokeColor = ViewController.redColor.cgColor
        layer.addSublayer(lineLayer)
        targetView.addSublayer(layer)
    }
    
    func drawText(text: String, frame: CGRect, targetView: UIView) {
        let label = UILabel(frame: frame)
        label.textAlignment = .center
        label.text = text
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.darkGray.withAlphaComponent(0.75)
    
        label.adjustsFontSizeToFitWidth = true
        
        targetView.addSubview(label)
    }
    
    func drawRect(rect: CGRect, isFillRect: Bool, targetLayer: CALayer) {
           let layer = CALayer()
           layer.borderColor = ViewController.redColor.cgColor
           layer.borderWidth = 1
           layer.frame = rect
           if (isFillRect) {
               layer.borderColor = ViewController.greenColor.cgColor
               layer.backgroundColor = ViewController.greenColor.cgColor
               layer.opacity = 0.5
           }
           targetLayer.addSublayer(layer)
       }
}
