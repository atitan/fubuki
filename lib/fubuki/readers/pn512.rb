require 'fubuki/reader'

module Fubuki
  module Readers
    class PN512 < Reader
      protocol :a, :b, :felica, :mifare
      baud_rate 106, 212, 424, 848
      buffer_size 64

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
        
      end

      def mifare_crypto1_deauthenticate
        
      end

      def picc_transceive
        
      end

      private

      def communicate_with_picc
      
      end
    end
  end
end
