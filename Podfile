platform :ios, '8.1'


pod 'DegradrMath', :path => '../DegradrMath'
pod 'DegradrCore3', :path => '../DegradrCore3'

pod 'Fabric'
pod 'Crashlytics'

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['DYLIB_COMPATIBILITY_VERSION'] = ''
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
end
