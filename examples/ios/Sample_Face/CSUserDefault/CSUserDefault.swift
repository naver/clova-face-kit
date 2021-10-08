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


class CSUserDefault {
    private var userDefault: UserDefaults {
        return UserDefaults.standard
    }
    static let shared = CSUserDefault()

    func value<T>(in key: CSUserDefaultKey) -> T {
        guard let value = userDefault.object(forKey: key.rawValue) as? T else {
            guard let defaultValue = key.defaultValue as? T else {
                fatalError("DEFAULT VALUE SHOULD MATCH API TYPE")
            }
            return defaultValue
        }
        return value
    }

    func update<T>(value: T, in key: CSUserDefaultKey) {
        userDefault.set(value, forKey: key.rawValue)
    }
}
