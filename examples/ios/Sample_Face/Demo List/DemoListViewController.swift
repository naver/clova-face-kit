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


protocol DemoListViewControllerDelegate: AnyObject {
    func demoListViewController(_ demoListViewController: DemoListViewController,
                                didSelectDemo selectedDemo: DemoCategory)
}

class DemoListViewController: UITableViewController {
    private let demoList: [DemoCategory] = [.newFaceDemo, .legacyFaceDemo]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < demoList.count else { return }
        self.pushViewController(selectedDemo: demoList[indexPath.row])
    }

    private func pushViewController(selectedDemo: DemoCategory) {

        let viewController = UIStoryboard(name: selectedDemo.storyboardName(), bundle: nil)
                             .instantiateViewController(withIdentifier: selectedDemo.viewControllerID())

        switch viewController {
        case let viewController as ViewController: // legacyFaceDemo
            let presenter = DemoPresenter()
            presenter.view = viewController
            let interactor = DemoInteractor()
            interactor.presenter = presenter
            viewController.interactor = interactor
        case let viewController as Clova_see_DemoViewController: // legacyFaceDemo
            let presenter = Clova_see_DemoPresenter()
            presenter.view = viewController
            let interactor = Clova_see_DemoInterator()
            interactor.presenter = presenter
            viewController.interactor = interactor
        default:
            break
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return demoList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")
        else {
            return UITableViewCell()
        }
        if indexPath.row < demoList.count {
            cell.textLabel?.text = demoList[indexPath.row].cellTitle
        }
        return cell
    }
}


private extension DemoCategory {
    func storyboardName() -> String {
        switch self {
        case .newFaceDemo:
            return "Clova_see"
        case .legacyFaceDemo:
            return "Main"
        }
    }

    func viewControllerID() -> String {
        switch self {
        case .newFaceDemo:
            return "Clova_see_DemoViewController"
        case .legacyFaceDemo:
            return "ViewController"
        }
    }

    var cellTitle: String {
        switch self {
        case .newFaceDemo:
            return "New Face Demo"
        case .legacyFaceDemo:
            return "Legacy Face Demo"
        }
    }
}
