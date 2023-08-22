# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

platform :osx, '11.3'


# workaround for link error. ref : https://stackoverflow.com/questions/75574268/missing-file-libarclite-iphoneos-a-xcode-14-3/75920796#75920796
post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '11.3'
      end
    end
  end
end


target 'Going Zero' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!
  # Pods for Going Zero
  pod 'F53OSC', :git => 'https://github.com/Figure53/F53OSC.git'

end
