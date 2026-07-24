#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_caesium_ffi.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_caesium_ffi'
  s.version          = '0.1.0'
  s.summary          = 'Fast image compression through libcaesium and Dart FFI.'
  s.description      = <<-DESC
Precompiled libcaesium bindings for Flutter.
                       DESC
  s.homepage         = 'https://github.com/zzzlazy/flutter_caesium_ffi'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'zzzlazy' => 'https://github.com/zzzlazy' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.vendored_frameworks = 'Frameworks/flutter_caesium_ffi.xcframework'
  s.preserve_paths = 'Frameworks/flutter_caesium_ffi.xcframework'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
