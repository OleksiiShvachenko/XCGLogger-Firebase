# Uncomment the next line to define a global platform for your project
use_frameworks!
inhibit_all_warnings!

workspace 'FirebaseLoggs.xcworkspace'

target 'XCGLogger+Firebase' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  platform :ios, '10.0'
  project 'XCGLogger+Firebase.xcodeproj'

  # Pods for XCGLogger+Firebase
  pod 'XCGLogger', '= 5.0.1'
  pod 'CryptoSwift', '= 0.7.0'
  pod 'FirebaseCommunity/Database', '= 0.1.2'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
