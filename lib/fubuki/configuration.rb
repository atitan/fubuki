module Fubuki
  class Configuration
    attr_accessor :reader, :default_transceive_timeout
    attr_accessor :startup, :read_register, :write_register
  end
end
