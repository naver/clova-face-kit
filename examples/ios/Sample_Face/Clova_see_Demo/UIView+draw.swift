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

extension UIView {
    func drawText(frame: CGRect, text: String) {
        let label = UILabel(frame: frame)
        label.textAlignment = .center
        label.text = text
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.darkGray.withAlphaComponent(0.75)

        label.adjustsFontSizeToFitWidth = true

        self.addSubview(label)
    }
}
