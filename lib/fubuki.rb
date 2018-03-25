require 'fubuki/version'
require 'fubuki/core_ext'
require 'fubuki/exceptions'
require 'fubuki/configuration'

module Fubuki
  extend self

  def configuration
    @configuration ||= Configuration.new
  end

  def configure
    yield configuration
  end

  def reader
    return @reader if defined?(@reader) && @reader
    reader = configuration.reader
  end

  def reader=(model)
    require "fubuki/readers/#{model.downcase}"
    klass_name = model.to_s.upcase
    @reader = Fubuki::Readers.const_get(klass_name)
  end

  def method_missing(sym, *args, &block)
    return reader.send(sym, *args) if reader.respond_to?(sym)
    super
  end
end
