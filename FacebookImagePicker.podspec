Pod::Spec.new do |s|
  s.name             = "FacebookImagePicker"
  s.version          = "1.0.1"
  s.summary          = "Ocean Labs FacebookImagePicker"
  s.homepage         = "https://github.com/OceanLabs/FacebookImagePicker-iOS"
  s.license          = 'MIT'
  s.author           = { "Deon Botha" => "deon@oceanlabs.co" }
  s.source           = { :git => "git@github.com:OceanLabs/FacebookImagePicker-iOS.git", :branch => 'photoMosaic' }

  s.platform     = :ios, '5.0'
  s.requires_arc = true

  s.source_files = ['OL*.{h,m}']
  s.resources = ['FacebookImagePicker.xcassets', '*.xib']

  s.dependency 'Facebook-iOS-SDK'
  s.dependency 'UIImageView+FadeIn'
  s.dependency 'UIDevice+Hardware'

end