#
# Be sure to run `pod lib lint dimplugins-objc.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name                  = 'DIMPlugins'
    s.version               = '0.7.1'
    s.summary               = 'Decentralized Instant Messaging'
    s.description           = <<-DESC
            Decentralized Instant Messaging (Objective-C SDK)
                              DESC
    s.homepage              = 'https://github.com/dimchat/sdk-objc'
    s.license               = { :type => 'MIT', :file => 'LICENSE' }
    s.author                = { 'Albert Moky' => 'albert.moky@gmail.com' }
    s.source                = { :git => 'https://github.com/dimchat/sdk-objc.git', :tag => s.version.to_s }
    # s.platform            = :ios, "11.0"
    s.ios.deployment_target = '11.0'

    s.source_files          = 'DIMPlugins/Classes', 'DIMPlugins/DIMPlugins/*.h', 'DIMPlugins/Classes/**/*.{h,inc,m,mm,c,cpp}'
    # s.exclude_files       = 'DIMPlugins/Classes/Exclude'
    s.public_header_files   = 'DIMPlugins/DIMPlugins/*.h', 'DIMPlugins/Classes/*.h', 'DIMPlugins/Classes/crypto/*.h', 'DIMPlugins/Classes/data/*.h', 'DIMPlugins/Classes/mkm/*.h'

    s.frameworks            = 'Security'
    # s.requires_arc        = true

    s.dependency 'DIMCore', '~> 0.7.1'
    s.dependency 'DaoKeDao', '~> 0.7.1'
    s.dependency 'MingKeMing', '~> 0.7.1'
end
