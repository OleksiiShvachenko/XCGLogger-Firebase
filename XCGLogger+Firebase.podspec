Pod::Spec.new do |s|
  s.name         = "XCGLogger+Firebase"
  s.version      = "0.0.1"
  s.summary      = "A short description of XCGLogger+Firebase."
  s.description  = "Plugin to integrate XCGLogger and Firebase"
  s.homepage     = "https://github.com/shalex9154/XCGLogger-Firebase"
  s.source       = { :git => "http://github.com/shalex9154/XCGLogger+Firebase.git", :tag => "#{s.version}" }
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Oleksii Shvachenko" => "shalex9154@gmail.com" }
  
  
  s.platform     = :ios, "10.0"
  s.source_files  = "XCGLogger+Firebase/FirebaseDestination.swift"
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0', 'SWIFT_OPTIMIZATION_LEVEL' => '-Owholemodule', 'SWIFT_DISABLE_SAFETY_CHECKS' => 'YES', 'GCC_UNROLL_LOOPS' => 'YES'}

  s.dependency "XCGLogger"
  s.dependency "CryptoSwift"
  s.dependency "FirebaseCommunity/Database"
end