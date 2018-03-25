require 'singleton'

module Fubuki
  class Reader
    include Singleton

    class << self
      def protocol?(types)
        @capability ||= types
      end

      def baud_rate(*types)
        @capability ||= types
      end

      def buffer_size
        @capability ||= types
      end

      def soft_reset
      end

      def config_reset
      end

      def internal_timer
      end

      def transceiver_baud_rate
      end

      def antenna_on
        
      end

      def antenna_off
        
      end

      def antenna_gain
      end

      def mifare_crypto1_authenticate
        raise 'dfbdbfs' unless capable_of?(:mifare)
      end

      def mifare_crypto1_deauthenticate
        
      end

      def transceive
        
      end
    end

    def initialize
      Fubiki.configuration.startup.call
      sleep 0.05

      soft_reset
      config_reset
      antenna_on
    end

    private

    def read_register(reg)
      Fubiki.configuration.read_register.call(reg)
    end

    def write_register(reg, data)
      Fubiki.configuration.write_register.call(reg, data)
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
