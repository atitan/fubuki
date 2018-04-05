require 'singleton'

module Fubuki
  class Reader
    include Singleton

    class << self
      def transceive(protocol, *args)
        raise UnsupportedProtocolError unless protocol?(protocol)
        instance.transceive(protocol, *args)
      end

      def method_missing(sym, *args)
        return instance.send(sym, *args) if instance.respond_to?(sym)

        super
      end

      private

      def spec(feature, capabilities)
        instance_variable_set("@#{feature}", capabilities)
        instance_eval <<-STR, __FILE__, __LINE__ + 1
          def #{feature}
            @#{feature}
          end
          def #{feature}?(capabilitiy)
            return nil unless #{feature}.is_a?(Array)
            #{feature}.include?(capabilitiy)
          end
        STR
      end
    end

    def initialize
      Fubuki.configuration.startup.call
      sleep 0.05

      soft_reset
      config_reset
      antenna_on
    end

    private

    def read_register(reg)
      Fubuki.configuration.read_register.call(reg)
    end

    def write_register(reg, data)
      Fubuki.configuration.write_register.call(reg, data)
    end

    def set_register_bitmask(reg, mask)
      value = read_register(reg)
      write_register(reg, value | mask)
    end

    def clear_register_bitmask(reg, mask)
      value = read_register(reg)
      write_register(reg, value & (~mask))
    end
  end
end
