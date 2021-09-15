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

#define CHRONO_ALWAYS_ON

#include <chrono>
#include <iostream>
#include <numeric>
#include <random>
#include <string>
#include <thread>

#include "base/chrono.h"
#include "base/face.h"
#include "base/feature.h"
#include "base/frame.h"
#include "base/macros.h"
#include "base/path.h"
#include "base/settings.h"
#include "face/options.h"
#include "sdk/clova_see.h"
#include "sdk/measure_result.h"
#include "test/image.h"
#include "test/people_search.h"
#include "third_parties/fmt/include/fmt/format.h"
#include "third_parties/range_v3/include/range/v3/action/join.hpp"
#include "third_parties/range_v3/include/range/v3/algorithm/max_element.hpp"
#include "third_parties/range_v3/include/range/v3/view/filter.hpp"
#include "third_parties/range_v3/include/range/v3/view/transform.hpp"

#if USE_STD_FILESYSTEM
  #include <filesystem>
#else
  #include <dirent.h>
#endif  // USE_STD_FILESYSTEM

namespace {

using PerformanceMode = clova::Settings::PerformanceMode;

////////////////////////////////////////////////////////////////////////////////
// class BenchmarkImageDispenser

class BenchmarkImageDispenser {
 public:
  explicit BenchmarkImageDispenser(const clova::Paths& paths);
  virtual ~BenchmarkImageDispenser();

  clova::test::Image RandomNext() const;

 private:
  const clova::Paths paths_;
  mutable std::mt19937 randomizer_;
  mutable std::uniform_int_distribution<int> distributor_;
};

BenchmarkImageDispenser::BenchmarkImageDispenser(const clova::Paths& paths)
    : paths_(paths),
      randomizer_(std::random_device()()),
      distributor_(0, std::max<int>(0, paths.size() - 1)) {
  assert(!paths_.empty());
}

BenchmarkImageDispenser::~BenchmarkImageDispenser() {
}

clova::test::Image BenchmarkImageDispenser::RandomNext() const {
  assert(!paths_.empty());
  return clova::test::Image::New(paths_.at(distributor_(randomizer_)));
}

////////////////////////////////////////////////////////////////////////////////
// File System

bool IsExtensionJpg(const clova::Path& extension) {
  return extension.compare(".jpeg") == 0 || extension.compare(".jpg") == 0;
}

#if USE_STD_FILESYSTEM

bool IsJpgEntry(const std::filesystem::directory_entry& entry) {
  return IsExtensionJpg(entry.path().extension().string());
}

clova::Path ToPath(const std::filesystem::directory_entry& entry) {
  return entry.path().string();
}

clova::Paths GetBenchmarkImagePaths(const clova::Path& directory) {
  const auto& iterator = std::filesystem::directory_iterator(directory);
  return iterator | ranges::views::filter(IsJpgEntry)
                  | ranges::views::transform(ToPath)
                  | ranges::to<clova::Paths>();
}

#else

clova::Path GetExtension(const clova::Path& path) {
  const auto& position = path.rfind(".");
  if (position == clova::Path::npos)
    return clova::Path();
  return path.substr(position, path.size() - position);
}

bool IsJpgEntry(const clova::Path& entry) {
  return IsExtensionJpg(GetExtension(entry));
}

clova::Path JoinPaths(const clova::Path& path1, const clova::Path& path2) {
  clova::Path path1_with_delimiter = path1;
  if (path1.back() != '/')
    path1_with_delimiter.push_back('/');
  return path1_with_delimiter + path2;
}

clova::Paths GetBenchmarkImagePaths(const clova::Path& directory) {
  DIR* dir = NULL;
  if ((dir = opendir(directory.c_str())) == NULL)
    return clova::Paths();

  clova::Paths result;
  struct dirent* entry = NULL;
  while ((entry = readdir(dir)) != NULL) {
    if (IsJpgEntry(entry->d_name))
      result.emplace_back(JoinPaths(directory, entry->d_name));
  }
  return result;
}

#endif  // USE_STD_FILESYSTEM

////////////////////////////////////////////////////////////////////////////////
// Common

constexpr size_t kTableColumnWidth = 10;

const std::vector<std::string> kTableColumnLabels {
  "FPS", "Total", "D", "L", "A", "E", "R", "MD", "SD"
};

std::string ToString(const PerformanceMode& performance_mode) {
  switch (performance_mode) {
    case PerformanceMode::kAccurate106:
      return "kAccurate106";
    case PerformanceMode::kAccurate98:
      return "kAccurate98";
    case PerformanceMode::kFast:
      return "kFast";
    default:
      clova::UNREACHABLE();
  }
}

void PrintTableDivider() {
  fmt::print("{:─^{}}\n", "", kTableColumnLabels.size() * kTableColumnWidth);
}

void PrintPreamble(const clova::Settings& settings) {
  std::vector<std::string> contents {
    fmt::format(" number of threads : {} ", settings.number_of_threads),
    fmt::format(" performance mode  : {} ",
                ToString(settings.performance_mode)),
  };
  const auto& maximum_length =
      ranges::max_element(contents, std::less<>(), &std::string::size)->size();

  fmt::print("┌{0:─^{1}}┐\n", "", maximum_length);
  for (const auto& content : contents)
    fmt::print("│{0: <{1}}│\n", content, maximum_length);
  fmt::print("└{0:─<{1}}┘\n", "", maximum_length);
}

void PrintTableHeader() {
  const auto& decorator = [](const auto& column) {
    return fmt::format("{: >{}}", column, kTableColumnWidth);
  };
  const auto& header = kTableColumnLabels
      | ranges::views::transform(decorator)
      | ranges::actions::join
      | ranges::to<std::string>();

  fmt::print("{}\n", header);
}

void PrintTableRow(const clova::MeasureResult& result) {
  const std::vector<std::pair<float, std::string>> values_and_units {
    { result.total_fps, "fps" },
    { 1000.0f / result.total_fps, "ms" },
    { result.detector_in_milli, "ms" },
    { result.landmarker_in_milli, "ms" },
    { result.aligner_in_milli, "ms" },
    { result.estimator_in_milli, "ms" },
    { result.recognizer_in_milli, "ms" },
    { result.mask_detector_in_milli, "ms" },
    { result.spoofing_detector_in_milli, "ms" },
  };
  const auto& decorator = [](const auto& pair) {
    return fmt::format("{: >{}}",
                       fmt::format("{:.2f}{}", pair.first, pair.second),
                       kTableColumnWidth);
  };
  const auto& row = values_and_units
      | ranges::views::transform(decorator)
      | ranges::actions::join
      | ranges::to<std::string>();

  fmt::print("{}\n", row);
}

void PrintTableFooter(const std::vector<clova::MeasureResult>& results) {
  auto average = std::accumulate(results.cbegin(),
                                 results.cend(),
                                 clova::MeasureResult())
               / results.size();
  PrintTableRow(average);
  std::cout << std::endl;
}

clova::Settings NewSettings(int number_of_threads,
                            const PerformanceMode& performance_mode) {
  return clova::SettingsBuilder()
      .SetIntermittentInformationRatio(1)
      .SetNumberOfThreads(number_of_threads)
      .SetPerformanceMode(performance_mode)
      .Build();
}

void DoBenchmark(const BenchmarkImageDispenser& dispenser,
                 size_t repeat_count,
                 size_t logging_step,
                 const clova::Settings& settings = clova::Settings()) {
  const bool do_logging = logging_step != 0;
  clova::ClovaSee clova_see(settings);
  clova::MeasureResult measure_result;
  std::vector<clova::MeasureResult> measure_results;

  if (do_logging) {
    PrintPreamble(settings);
    PrintTableHeader();
    PrintTableDivider();
  }

  const auto& options = clova::face::OptionsBuilder()
      .SetBoundingBoxThreshold(0.7f)
      .SetInformationToObtain(clova::face::Options::kAll)
      .SetResizeThreshold(320)
      .SetSmoothingContour(true)
      .SetSmoothingRect(false)
      .Build();

  for (size_t count = 0; count < repeat_count; ++count) {
    clova_see.Run(dispenser.RandomNext().frame(), options);
    measure_result += clova_see.GetMeasureResult();
    if (do_logging && (count % logging_step == logging_step - 1)) {
      const auto& measure_result_mean = measure_result / logging_step;
      PrintTableRow(measure_result_mean);
      measure_results.push_back(measure_result_mean);
      measure_result.Reset();
    }
  }

  if (do_logging) {
    PrintTableDivider();
    PrintTableFooter(measure_results);
    measure_results.clear();
  }
}

void DoWarmUp(const BenchmarkImageDispenser& dispenser) {
  std::cout << "Warming Up" << std::flush;
  for (size_t count = 0; count < 10; ++count) {
    DoBenchmark(dispenser, 10, 0);
    std::cout << "." << std::flush;
  }
  std::cout << std::endl << std::endl;
}

void DoCoolDown() {
  std::cout << "Cooling Down" << std::flush;
  for (size_t count = 0; count < 10; ++count) {
    std::this_thread::sleep_for(std::chrono::seconds(1));
    std::cout << "." << std::flush;
  }
  std::cout << std::endl << std::endl;
}

void DoPeopleSearchBenchmark() {
  const std::vector<uint32_t> populations { 100000, 50000, 10000, 5000, 1000 };
  const auto& maximum_length = std::to_string(
      *ranges::max_element(populations.cbegin(), populations.cend())).length();

  for (const auto& population : populations) {
    const auto& people_search = clova::test::PeopleSearch::New(population);
    float people_search_in_milli = 0.0f;

    using namespace clova;
    measure_in_milli(people_search_in_milli) {
      people_search->Find(clova::Feature(512));
    }

    fmt::print("Feature Matching 1:{1:>{0}}: {2:>{0}.2f}ms\n",
              maximum_length,
              people_search->people().size(),
              people_search_in_milli);
  }
}

}  // namespace

////////////////////////////////////////////////////////////////////////////////
// main()

int main(int argc, char* argv[]) {
  const auto& directory = argc == 2 ? argv[1] : ".";
  const auto& benchmark_image_paths = GetBenchmarkImagePaths(directory);
  if (benchmark_image_paths.empty()) {
    std::cerr << "There are no benchmark images: " << directory << std::endl;
    return EXIT_FAILURE;
  }

  BenchmarkImageDispenser dispenser(benchmark_image_paths);
  DoWarmUp(dispenser);

  for (const auto& number_of_threads: { 1, 2, 4 }) {
    for (const auto& performance_mode : { PerformanceMode::kAccurate106,
                                          PerformanceMode::kAccurate98,
                                          PerformanceMode::kFast }) {
      DoBenchmark(dispenser,
                  100,  // repeat_count
                  10,   // logging_step
                  NewSettings(number_of_threads, performance_mode));
      DoCoolDown();
    }
  }

  DoPeopleSearchBenchmark();

  return EXIT_SUCCESS;
}
