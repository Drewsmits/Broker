Pod::Spec.new do |s|
  s.name         = "Broker"
  s.version      = "0.0.1"
  s.summary      = "A lightweight network layer built on NSURLSession."
  s.license      = 'MIT'
  s.author       = { 
    "Andrew Smith" => "drewsmits@gmail.com"
  }
  s.social_media_url = "http://twitter.com/drewsmits"
  s.requires_arc = true
  s.platform     = :ios, '7.0'
  s.source       = { 
    :git => "https://github.com/Drewsmits/Broker.git", 
    :tag => s.version.to_s 
  }
  s.homepage = "http://github.com/Drewsmits/Broker"
  s.source_files  = 'Broker/*.{h,m}'
  s.public_header_files = 'Broker/*.h'
  s.frameworks = 'Foundation', 'CoreData'
end
