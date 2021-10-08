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

import UIKit
import AVFoundation


protocol Clova_see_DemoViewProtocol: AnyObject {
    func clear()
    func drawContour(points: [CGPoint], size: CGSize)
    func drawEulerAngle(eulerAngleDescription: String, faceBoundingRect: CGRect, size: CGSize)
    func drawMaskDetectionResult(isMasked: Bool, faceBoundingRect: CGRect, size: CGSize)
    func drawSpoofingDetectionResult(isSpoofed: Bool, faceBoundingRect: CGRect, size: CGSize)
    func drawCapturesFace(image: UIImage)
    func drawSimilarity(similarity: Float?)
}


class Clova_see_DemoViewController: UIViewController, Clova_see_DemoViewProtocol {
    @IBOutlet weak var cameraPreviewWrapperView: UIView!
    @IBOutlet weak var capturedFaceImageView: UIImageView!
    @IBOutlet weak var similarityLabel: UILabel!

    private static let greenColor = UIColor.init(red: 0, green: 199 / 255, blue: 60 / 255, alpha: 1)
    private static let redColor = UIColor.init(red: 200 / 255, green: 0, blue: 10 / 255, alpha: 1)

    var interactor: Clova_see_DemoInteratorProtocol?

    private var landmarkFrameLayer: CALayer = {
        let layer = CALayer()
        layer.borderColor = Clova_see_DemoViewController.greenColor.cgColor
        layer.borderWidth = 1
        layer.drawsAsynchronously = true
        layer.shouldRasterize = true
        return layer
    }()

    private var headPoselabelView: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = .clear
        return view
    }()

    private var faceFrameLayer: CALayer = {
        let layer = CALayer()
        layer.borderColor = Clova_see_DemoViewController.redColor.cgColor
        layer.borderWidth = 1
        layer.drawsAsynchronously = true
        layer.shouldRasterize = true
        return layer
    }()

    private var masklabelView: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = .clear
        return view
    }()

    private var liveneseeLayer: CALayer = {
        let layer = CALayer()
        layer.drawsAsynchronously = true
        layer.shouldRasterize = true
        return layer
    }()

    lazy private var previewLayer: AVCaptureVideoPreviewLayer? = {
        guard let session = interactor?.captureSession else { return nil }
        var previewLay = AVCaptureVideoPreviewLayer(session: session)
        previewLay.videoGravity = .resizeAspectFill
        return previewLay
    }()


    // MARK: - ViewContrroller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.previewLayer?.frame = view.frame
        guard let previewLayer = self.previewLayer else { return }
        self.cameraPreviewWrapperView.layer.addSublayer(previewLayer)

        self.interactor?.startDetecting()
    }

    // MARK: - UI Events
    @IBAction private func didTouchUpSettingButton(_ button: UIButton) {
        let alertViewController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (_) in
            guard let self = self else { return }
            self.interactor?.endChangingDetectorOption()
        }
        alertViewController.addAction(cancelAction)

        let viewController = UIStoryboard(name: "Setting", bundle: nil).instantiateViewController(withIdentifier: "SettingViewController")
        alertViewController.setValue(viewController, forKey: "contentViewController")

        self.present(alertViewController, animated: true)
    }

    @IBAction private func didTouchUpShootButton(_ button: UIButton) {
        self.interactor?.capturePhoto()
    }

    @IBAction private func didTouchUpCameraToggleButton(_ button: UIButton) {
        self.interactor?.switchCamera()
    }

    // MARK: - Clova_see_DemoViewProtocol
    func clear() {
        self.faceFrameLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.faceFrameLayer.removeFromSuperlayer()
        self.headPoselabelView.subviews.forEach { $0.removeFromSuperview() }
        self.landmarkFrameLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.landmarkFrameLayer.removeFromSuperlayer()
        self.liveneseeLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.masklabelView.subviews.forEach { $0.removeFromSuperview() }
    }

    func drawContour(points: [CGPoint], size: CGSize) {
        let preferredSize = self.view.frame.size
        let scaledPoints = points.map { $0.changeScale(to: preferredSize, parentScreenSize: size) }

        self.landmarkFrameLayer.drawPoints(points: scaledPoints,
                                           fillColor: Clova_see_DemoViewController.greenColor.cgColor,
                                           layerFrame: self.view.frame)
        self.view.layer.addSublayer(self.landmarkFrameLayer)
    }

    func drawEulerAngle(eulerAngleDescription: String, faceBoundingRect: CGRect, size: CGSize) {
        let preferredSize = self.view.frame.size
        let scaledRect = faceBoundingRect.changeScale(to: preferredSize, parentScreenSize: size)

        let frame = CGRect(x: scaledRect.origin.x,
                           y: scaledRect.origin.y - 20,
                           width: scaledRect.width,
                           height: 20)

        self.headPoselabelView.drawText(frame: frame, text: eulerAngleDescription)
        self.view.addSubview(self.headPoselabelView)
    }

    func drawMaskDetectionResult(isMasked: Bool, faceBoundingRect: CGRect, size: CGSize) {
        let preferredSize = self.view.frame.size
        let scaledRect = faceBoundingRect.changeScale(to: preferredSize, parentScreenSize: size)

        let borderColor: CGColor
        let backgroundColor: CGColor
        let maskDescription: String

        if isMasked {
            borderColor = Clova_see_DemoViewController.greenColor.cgColor
            backgroundColor = Clova_see_DemoViewController.greenColor.cgColor
            maskDescription = "Mask ON"
        } else {
            borderColor = Clova_see_DemoViewController.redColor.cgColor
            backgroundColor = UIColor.clear.cgColor
            maskDescription = "Mask OFF"
        }

        self.faceFrameLayer.drawRect(rect: scaledRect, borderColor: borderColor, backgroundColor: backgroundColor)

        let frame = CGRect(x: scaledRect.origin.x,
                           y: scaledRect.origin.y,
                           width: scaledRect.width / 2,
                           height: 20)

        self.masklabelView.drawText(frame: frame, text: maskDescription)

        self.view.layer.addSublayer(self.faceFrameLayer)
        self.view.addSubview(self.masklabelView)
    }

    func drawSpoofingDetectionResult(isSpoofed: Bool, faceBoundingRect: CGRect, size: CGSize) {
        let preferredSize = self.view.frame.size

        if (isSpoofed) {
            let scaledRect = faceBoundingRect.changeScale(to: preferredSize, parentScreenSize: size)

            let left = scaledRect.origin.x
            let top = scaledRect.origin.y
            let right = scaledRect.origin.x + scaledRect.size.width
            let bottom = scaledRect.origin.y + scaledRect.size.height

            self.liveneseeLayer.drawLine(from: CGPoint(x: left, y: top),
                                         to: CGPoint(x: right, y: bottom),
                                         layerFrame: self.view.frame,
                                         strokeColor: Clova_see_DemoViewController.redColor.cgColor)

            self.liveneseeLayer.drawLine(from: CGPoint(x: right, y: top),
                                         to: CGPoint(x: left, y: bottom),
                                         layerFrame: self.view.frame,
                                         strokeColor: Clova_see_DemoViewController.redColor.cgColor)
        }
        self.view.layer.addSublayer(self.liveneseeLayer)
    }

    func drawCapturesFace(image: UIImage) {
        if self.capturedFaceImageView.isHidden {
            self.capturedFaceImageView.isHidden = false
        }
        self.capturedFaceImageView.image = image
    }

    func drawSimilarity(similarity: Float?) {
        if self.similarityLabel.isHidden {
            self.similarityLabel.isHidden = false
        }

        if let similarity = similarity {
            self.similarityLabel.text = String(format: "similarity: %4.2f", arguments: [similarity])
        }
    }
}
