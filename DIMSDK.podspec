#
# Be sure to run `pod lib lint dkd-objc.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DIMSDK'
  s.version          = '0.4.4'
  s.summary          = 'Decentralized Instant Messaging (Objective-C SDK)'
  s.homepage         = 'https://github.com/dimchat'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DIM' => 'john.chen@infothinker.com' }
  s.source           = { :git => 'https://github.com/dimchat/sdk-objc.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'

  s.source_files = 'Classes/**/*'

  s.dependency 'DIMCore', '~> 0.4.0'
end
