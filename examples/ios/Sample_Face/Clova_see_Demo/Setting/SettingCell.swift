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


protocol SettingCellDelegate: AnyObject {
    func settingCell(_ cell: SettingCell, didChangeSwitchValue isOn: Bool)
}

class SettingCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var settingSwitch: UISwitch!

    weak var delegate: SettingCellDelegate?

    @IBAction private func didChangeSwitchValue(_ sender: UISwitch) {
        self.delegate?.settingCell(self, didChangeSwitchValue: sender.isOn)
    }

    func update(title: String, and switchWasOn: Bool) {
        self.titleLabel.text = title
        self.settingSwitch.isOn = switchWasOn
    }
}
