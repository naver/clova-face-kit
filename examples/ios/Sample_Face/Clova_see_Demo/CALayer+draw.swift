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

extension CALayer {
    func drawRect(rect: CGRect, borderColor: CGColor, backgroundColor: CGColor) {
        let layer = CALayer()
        layer.borderColor = borderColor
        layer.backgroundColor = backgroundColor
        layer.borderWidth = 1
        layer.opacity = 0.5
        layer.frame = rect

        self.addSublayer(layer)
    }


    func drawLine(from pointA: CGPoint, to pointB: CGPoint, layerFrame: CGRect, strokeColor: CGColor) {
        let layer = CALayer()
        layer.frame = layerFrame

        let lineLayer = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: pointA)
        linePath.addLine(to: pointB)
        lineLayer.path = linePath.cgPath
        lineLayer.fillColor = nil
        lineLayer.opacity = 1.0
        lineLayer.strokeColor = strokeColor
        layer.addSublayer(lineLayer)

        self.addSublayer(layer)
    }


    func drawPoints(points: [CGPoint], fillColor: CGColor, layerFrame: CGRect, pointSize: Int = 3) {
        let layer = CALayer()
        layer.frame = layerFrame
        for value in points {
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = UIBezierPath(ovalIn: CGRect(origin: value,
                                                          size: CGSize(width: pointSize,
                                                                       height: pointSize))).cgPath
            shapeLayer.fillColor = fillColor
            layer.addSublayer(shapeLayer)
        }

        self.addSublayer(layer)
    }
}
