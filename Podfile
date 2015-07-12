source 'https://github.com/CocoaPods/Specs.git'

target 'GraphitiKit-iOS', :exclusive => true do
  pod "GraphitiKit-iOS", :path => "../"
  pod "AWSiOSSDKv2",'~> 2.0'
  pod 'PureLayout'
  
  #post_install hook
#  post_install do |installer_representation|
#      installer_representation.project.build_configurations.each do |config|
#          if config.name == 'Debug'
#              puts "  config.name: #{config.name}"
#              puts "      before hooking:"
#              puts "        inspect: #{config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'].inspect}"
#              config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
#              config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'GK_COMPILE_TIME_LOG_LEVEL=ASL_LEVEL_ERR'
#              puts "      after hooking:"
#              puts "        inspect: #{config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'].inspect}"
#          end
#      end
#  end

end

target 'Tests', :exclusive => true do
  pod "GraphitiKit-iOS", :path => "../"
end