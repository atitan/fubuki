require File.expand_path("../lib/fubuki/version.rb", __FILE__)

Gem::Specification.new do |s|
  s.name          = 'fubuki'
  s.version       = Fubuki::VERSION
  s.date          = '2021-05-31'
  s.summary       = 'This is the project planned to replace MFRC522_Ruby in the future.'
  s.authors       = ['atitan']
  s.email         = ['commit@atifans.net']
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/atitan/fubuki'
  s.license       = 'MIT'

  s.files       = Dir['{lib,ext}/**/*.{rb,h,c}']
  s.extensions  = ['ext/fubuki/extconf.rb']

  s.add_development_dependency 'rake-compiler'
  s.add_development_dependency 'rake'
end
