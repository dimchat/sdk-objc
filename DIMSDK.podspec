#
# Be sure to run `pod lib lint sdk-objc.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name                  = 'DIMSDK'
    s.version               = '1.2.0'
    s.summary               = 'Decentralized Instant Messaging Software Development Kit'
    s.homepage              = 'https://github.com/dimchat/sdk-objc'
    s.license               = { :type => 'MIT', :file => 'LICENSE' }
    s.author                = { 'Albert Moky' => 'albert.moky@gmail.com' }
    s.source                = { :git => 'https://github.com/dimchat/sdk-objc.git', :tag => s.version.to_s }
    # s.platform            = :ios, "12.0"
    s.ios.deployment_target = '12.0'

    s.source_files          = 'Classes', 'Classes/**/*.{h,m}', 'DIMSDK/DIMSDK/*.h'
    # s.exclude_files       = 'Classes/Exclude'
    s.public_header_files   = 'Classes/**/*.h', 'DIMSDK/DIMSDK/*.h'

    # s.frameworks          = 'Security'
    # s.requires_arc        = true

    s.dependency 'DIMCore', '~> 1.2.0'
    s.dependency 'DaoKeDao', '~> 1.2.0'
    s.dependency 'MingKeMing', '~> 1.2.0'
end
