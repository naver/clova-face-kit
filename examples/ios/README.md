
### How to build

- go to clova-face-kit root directory

```
examples)

 mkdir -p build
 
 cd build
 python ../scripts/build.py --platform=ios --backend=ncnn --release 

```
- copy `clovasee.all.bundle` to the ios sample project
- created build/ios-framework/clova_see.xcframework
- copy `clova_see.xcframework` to the ios sample project
- set Embed & Signs in Xcode build settings

### Requirement

- C++14 support should be setting ```C++ Language Dialect``` to ```GNU++14```
