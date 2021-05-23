require File.expand_path("../lib/fubuki/version.rb", __FILE__)

Gem::Specification.new do |s|
  s.name          = 'fubuki'
  s.version       = Fubuki::VERSION
  s.date          = '2021-05-23'
  s.summary       = 'SPI Library.'
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
