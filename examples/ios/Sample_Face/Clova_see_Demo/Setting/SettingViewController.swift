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

class SettingViewController: UITableViewController, SettingCellDelegate {
    private let optionKeys: [CSUserDefaultKey] = [.availableDetector, .availableTracker, .availableLandmarker,
                                                  .availableAligner, .availableRecognizer, .availableEstimator,
                                                  .availableMaskDetector, .availableSpoofingDetector]

    // MARK: - ViewContrroller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize.height = 300
    }

    // MARK: - UITableViewDatasource
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as? SettingCell else {
            fatalError("failed to dequeueResuableCell. cell's identifier: `SettingCell`")
        }

        let option = optionKeys[indexPath.row]
        let optionWasOn: Bool = CSUserDefault.shared.value(in: option)
        cell.update(title: option.optionName, and: optionWasOn)
        cell.delegate = self

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionKeys.count
    }

    // MARK: - SettingCellDelegate
    func settingCell(_ cell: SettingCell, didChangeSwitchValue isOn: Bool) {
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            fatalError("failed to find indexPath")
        }

        CSUserDefault.shared.update(value: isOn, in: optionKeys[indexPath.row])
    }
}


private extension CSUserDefaultKey {
    var optionName: String {
        switch self {
        case .availableDetector:
            return "Detector"
        case .availableTracker:
            return "Tracker"
        case .availableLandmarker:
            return "Landmarker"
        case .availableAligner:
            return "Aligner"
        case .availableRecognizer:
            return "Recognizer"
        case .availableEstimator:
            return "Estimator"
        case .availableMaskDetector:
            return "MaskDetector"
        case .availableSpoofingDetector:
            return "SpoofingDetector"
        }
    }
}
