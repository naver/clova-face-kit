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

package ai.clova.see.example

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.navigation.Navigation
import timber.log.Timber

private const val REQUEST_CODE_PERMISSIONS = 1234
private val PERMISSIONS_REQUIRED = arrayOf(Manifest.permission.CAMERA)

class PermissionsFragment : Fragment() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (hasPermissions(requireContext())) {
            navigateToCameraFragment()
        } else {
            requestPermissions(PERMISSIONS_REQUIRED, REQUEST_CODE_PERMISSIONS)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE_PERMISSIONS) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                navigateToCameraFragment()
            } else {
                Timber.d("permissions denied")
            }
        }
    }

    private fun navigateToCameraFragment() {
        Navigation.findNavController(requireActivity(), R.id.fragment_holder)
            .navigate(PermissionsFragmentDirections.actionPermissionsToCamera())
    }

    companion object {
        fun hasPermissions(context: Context) = PERMISSIONS_REQUIRED.all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
    }
}
