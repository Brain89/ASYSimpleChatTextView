#
# Be sure to run `pod lib lint ASYSimpleChatTextView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "ASYSimpleChatTextView"
  s.version          = "0.5.3"
  s.summary          = "Tool to create a simple chat TextView"

  s.description      = <<-DESC
Tool to create a simple chat TextView<<-DESC
                       DESC

  s.homepage         = "https://github.com/Brain89/ASYSimpleChatTextView"
  s.license          = 'MIT'
  s.author           = { "Sychev Aleksandr" => "brain89g@gmail.com" }
  s.source           = { :git => "https://github.com/Brain89/ASYSimpleChatTextView.git", :tag => s.version.to_s }
  s.header_mappings_dir = 'Pod/Classes'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
end
