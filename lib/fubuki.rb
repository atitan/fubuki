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

    set_reader(configuration.reader)
  end

  def set_reader(model)
    require "fubuki/readers/#{model.to_s.downcase}"
    klass_name = model.to_s.upcase
    @reader = Fubuki::Readers.const_get(klass_name)
  end

  def protocol
    return @protocol if defined?(@protocol) && @protocol

    raise UndefinedProtocolError
  end

  def protocol=(type)
    raise UnsupportedProtocolError unless reader.protocol?(type.to_sym)

    require "fubuki/protocols/#{type.to_s.downcase}"
    klass_name = type.to_s.capitalize
    @protocol = Fubuki::Protocols.const_get(klass_name)
  end

  def method_missing(sym, *args, &block)
    return protocol.send(sym, *args, &block) if protocol.respond_to?(sym)

    super
  end
end
