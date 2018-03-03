require File.expand_path("../lib/fubuki/version.rb", __FILE__)

Gem::Specification.new do |s|
  s.name          = 'fubuki'
  s.version       = Fubuki::VERSION
  s.date          = '2018-03-03'
  s.summary       = ''
  s.authors       = ['atitan']
  s.email         = ['commit@atifans.net']
  s.files         = Dir['lib/**/*']
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/atitan/fubuki'
  s.license       = 'MIT'
end