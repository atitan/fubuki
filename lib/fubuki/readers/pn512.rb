require 'fubuki/reader'

module Fubuki
  module Readers
    class PN512 < Reader
      # PCD commands
      PCD_Idle        = 0x00 # no action, cancels current command execution
      PCD_Config      = 0x01 # Configures the PN512 for FeliCa, MIFARE and NFCIP-1 communication
      PCD_GenRandomID = 0x02 # generates a 10-byte random ID number
      PCD_CalcCRC     = 0x03 # activates the CRC coprocessor or performs a self test
      PCD_Transmit    = 0x04 # transmits data from the FIFO buffer
      PCD_NoCmdChange = 0x07 # no command change, can be used to modify the CommandReg register bits without affecting the command, for example, the PowerDown bit
      PCD_Receive     = 0x08 # activates the receiver circuits
      PCD_Transceive  = 0x0C # transmits data from FIFO buffer to antenna and automatically activates the receiver after transmission
      PCD_AutoColl    = 0x0D # Handles FeliCa polling (Card Operation mode only) and MIFARE anticollision (Card Operation mode only)
      PCD_MFAuthent   = 0x0E # performs the MIFARE standard authentication as a reader
      PCD_SoftReset   = 0x0F # resets the PN512

      # Selects the register page
      PageReg         = 0x00

      # Command and Status
      CommandReg      = 0x01 # Starts and stops command execution
      ComlEnReg       = 0x02 # Controls bits to enable and disable the passing of Interrupt Requests
      DivlEnReg       = 0x03 # Controls bits to enable and disable the passing of Interrupt Requests
      ComIrqReg       = 0x04 # Contains Interrupt Request bits
      DivIrqReg       = 0x05 # Contains Interrupt Request bits
      ErrorReg        = 0x06 # Error bits showing the error status of the last command executed
      Status1Reg      = 0x07 # Contains status bits for communication
      Status2Reg      = 0x08 # Contains status bits of the receiver and transmitter
      FIFODataReg     = 0x09 # In- and output of 64 byte FIFO-buffer
      FIFOLevelReg    = 0x0A # Indicates the number of bytes stored in the FIFO
      WaterLevelReg   = 0x0B # Defines the level for FIFO under- and overflow warning
      ControlReg      = 0x0C # Contains miscellaneous Control Registers
      BitFramingReg   = 0x0D # Adjustments for bit oriented frames
      CollReg         = 0x0E # Bit position of the first bit collision detected on the RF-interface

      # Command
      ModeReg         = 0x11 # Defines general modes for transmitting and receiving
      TxModeReg       = 0x12 # Defines the data rate and framing during transmission
      RxModeReg       = 0x13 # Defines the data rate and framing during receiving
      TxControlReg    = 0x14 # Controls the logical behavior of the antenna driver pins TX1 and TX2
      TxAutoReg       = 0x15 # Controls the setting of the antenna drivers
      TxSelReg        = 0x16 # Selects the internal sources for the antenna driver
      RxSelReg        = 0x17 # Selects internal receiver settings
      RxThresholdReg  = 0x18 # Selects thresholds for the bit decoder
      DemodReg        = 0x19 # Defines demodulator settings
      FelNFC1Reg      = 0x1A # Defines the length of the valid range for the receive package
      FelNFC2Reg      = 0x1B # Defines the length of the valid range for the receive package
      MifNFCReg       = 0x1C # Controls the communication in ISO/IEC 14443/MIFARE and NFC target mode at 106 kbit
      ManualRCVReg    = 0x1D # Allows manual fine tuning of the internal receiver
      TypeBReg        = 0x1E # Configure the ISO/IEC 14443 type B
      SerialSpeedReg  = 0x1F # Selects the speed of the serial UART interface

      # CFG
      CRCResultRegH   = 0x21 # Shows the actual MSB and LSB values of the CRC calculation
      CRCResultRegL   = 0x22
      GsNOffReg       = 0x23 # Selects the conductance of the antenna driver pins TX1 and TX2 for modulation, when the driver is switched off
      ModWidthReg     = 0x24 # Controls the setting of the ModWidth
      TxBitPhaseReg   = 0x25 # Adjust the TX bit phase at 106 kbit
      RFCfgReg        = 0x26 # Configures the receiver gain and RF level
      GsNOnReg        = 0x27 # Selects the conductance of the antenna driver pins TX1 and TX2 for modulation when the drivers are switched on
      CWGsPReg        = 0x28 # Selects the conductance of the antenna driver pins TX1 and TX2 for modulation during times of no modulation
      ModGsPReg       = 0x29 # Selects the conductance of the antenna driver pins TX1 and TX2 for modulation during modulation
      TModeReg        = 0x2A # Defines settings for the internal timer
      TPrescalerReg   = 0x2B
      TReloadRegH     = 0x2C # Describes the 16-bit timer reload value
      TReloadRegL     = 0x2D
      TCounterValRegH = 0x2E # Shows the 16-bit actual timer value
      TCounterValRegL = 0x2F

      # TestRegister
      TestSel1Reg     = 0x31 # General test signal configuration
      TestSel2Reg     = 0x32 # General test signal configuration and PRBS control
      TestPinEnReg    = 0x33 # Enables pin output driver on 8-bit parallel bus (Note: For serial interfaces only)
      TestPinValueReg = 0x34 # Defines the values for the 8-bit parallel bus when it is used as I/O bus
      TestBusReg      = 0x35 # Shows the status of the internal testbus
      AutoTestReg     = 0x36 # Controls the digital selftest
      VersionReg      = 0x37 # Shows the version
      AnalogTestReg   = 0x38 # Controls the pins AUX1 and AUX2
      TestDAC1Reg     = 0x39 # Defines the test value for the TestDAC1
      TestDAC2Reg     = 0x3A # Defines the test value for the TestDAC2
      TestADCReg      = 0x3B # Shows the actual value of ADC I and Q

      spec :protocol, [:a, :b, :felica, :mifare]
      spec :baud_rate, [106, 212, 424, 848, 1696, 3392]
      spec :buffer_size, 64

      def soft_reset
        write_register(CommandReg, PCD_SoftReset)
        sleep 0.05 # wait 50ms

        write_register(TModeReg, 0x87) # Start timer by setting TAuto=1, and higher part of TPrescalerReg
        write_register(TPrescalerReg, 0xFF) # Set lower part of TPrescalerReg, and results in 302us timer (f_timer = 13.56 MHz / (2*TPreScaler+1))
        write_register(RFCfgReg, 0x59)
        set_register_bitmask(TxControlReg, 0x84)
        write_register(RxSelReg, 0x80)
        write_register(ModeReg, 0x00)
        write_register(GsNOnReg, 0xFF)
        write_register(CWGsPReg, 0x3F)
        write_register(GsNOffReg, 0xF2)
        write_register(BitFramingReg, 0x00)
        write_register(WaterLevelReg, buffer_size - 9)
      end

      def config_reset
        antenna_off

        # Stop current command
        write_register(CommandReg, PCD_Idle)
        # Stop crypto1 communication
        mifare_deauthenticate
        # Clear ValuesAfterColl bit
        clear_register_bitmask(CollReg, 0x80)

        case @current_protocol
        when :a, :b
          transceiver_baud_rate(:tx, 106)
          transceiver_baud_rate(:rx, 106)
        when :felica
          transceiver_baud_rate(:tx, 212)
          transceiver_baud_rate(:rx, 212)
        else
          raise UnsupportedProtocolError
        end

        internal_timer(Fubuki.configuration.default_transceive_timeout)

        antenna_on
      end

      def apply_protocol(protocol)
        return if @current_protocol == protocol
        @current_protocol = protocol

        case protocol
        when :a
          write_register(RxThresholdReg, 0x55)
          write_register(ControlReg, 0x10)
          # Enable transceive parity bit
          clear_register_bitmask(ManualRCVReg, 0x10)
          # Force 100% ASK
          write_register(TxAutoReg, 0x40)
          write_register(ModGsPReg, 0x3F)
          # RxWait clock
          clear_and_set_register_bitmask(RxSelReg, 0x3F, 0x08)
        when :b
          write_register(RxThresholdReg, 0x50)
          write_register(TypeBReg, 0x00)
          write_register(ControlReg, 0x10)
          # Enable transceive parity bit
          clear_register_bitmask(ManualRCVReg, 0x10)
          # Set ASK
          write_register(TxAutoReg, 0x00)
          write_register(ModGsPReg, 0x11)
          # RxWait clock
          clear_and_set_register_bitmask(RxSelReg, 0x3F, 0x08)
        when :felica
          write_register(RxThresholdReg, 0x55)
          write_register(ControlReg, 0x10)
          # Disable transceive parity bit
          set_register_bitmask(ManualRCVReg, 0x10)
          # Set ASK
          write_register(TxAutoReg, 0x00)
          write_register(ModGsPReg, 0x12)
          # RxWait clock
          clear_and_set_register_bitmask(RxSelReg, 0x3F, 0x03)
        else
          raise UnsupportedProtocolError
        end

        config_reset
      end

      def internal_timer(timer = nil)
        if timer
          timer = (timer / 0.302).round
          write_register(TReloadRegH, (timer >> 8) & 0xFF)
          write_register(TReloadRegL, (timer & 0xFF))
        end
        (read_register(TReloadRegH) << 8) | read_register(TReloadRegL)
      end

      def transceiver_baud_rate(direction, value = nil)
        reg = {tx: TxModeReg, rx: RxModeReg}
        speed = {106 => 0, 212 => 1, 424 => 2, 848 => 3}
        mod = {0 => 0x26, 1 => 0x15, 2 => 0x0A, 3 => 0x05}

        if value
          value = speed.fetch(value)

          case @current_protocol
          when :a
            @built_in_crc_disabled = value == 0
            framing = 0b00
          when :b
            @built_in_crc_disabled = false
            framing = 0b11
          when :felica
            @built_in_crc_disabled = false
            framing = 0b10
          else
            raise UnsupportedProtocolError
          end

          # Set tx mod width
          if direction == :tx
            write_register(ModWidthReg, mod.fetch(value))
          end

          value <<= 4
          value |= framing
          value |= 0x80 unless @built_in_crc_disabled
          write_register(reg.fetch(direction), value)
        end

        (read_register(reg.fetch(direction)) >> 4) & 0x07
      end

      def antenna_on
        set_register_bitmask(TxControlReg, 0x03)
      end

      def antenna_off
        clear_register_bitmask(TxControlReg, 0x03)
      end

      def mifare_authenticate
        # Buffer[12]: {command, block_addr, sector_key[6], uid[4]}
        buffer = [command, block_addr]
        buffer.concat(sector_key[0..5])
        buffer.concat(uid[0..3])

        communicate_with_picc(PCD_MFAuthent, buffer)

        # Check MFCrypto1On bit
        (read_register(Status2Reg) & 0x08) != 0
      end

      def mifare_deauthenticate
        clear_register_bitmask(Status2Reg, 0x08) # Clear MFCrypto1On bit
      end

      def transceive(send_data, crc: true, rx_align: 0, tx_lastbits: 0)
        unless crc || @built_in_crc_disabled
          raise UsageError, 'Built-in CRC enabled while CRC is not wanted'
        end

        send_data = send_data.is_a?(Array) ? send_data.dup : [send_data]
        send_data.append_crc16(@current_protocol) if @built_in_crc_disabled && crc

        puts "Sending Data: #{send_data.to_bytehex}" if ENV['DEBUG']

        # Transfer data
        status, received_data, valid_bits = communicate_with_picc(PCD_Transceive, send_data, rx_align, tx_lastbits)
        return status, received_data, valid_bits if status != :status_ok

        puts "Received Data: #{received_data.to_bytehex}" if ENV['DEBUG']
        puts "Valid bits: #{valid_bits}" if ENV['DEBUG']

        # Data exists, check CRC
        if received_data.size > 2 && @built_in_crc_disabled && crc
          raise IncorrectCRCError unless received_data.check_crc16(@current_protocol, true)
        end

        return status, received_data, valid_bits
      end

      def collision_detail
        collision = read_register(CollReg)

        # CollPosNotValid - no collision detected or the position of the collision is out of the range
        return false if (collision & 0x20) != 0
              
        collision_position = collision & 0x1F
        collision_position = 32 if collision_position == 0 # Values 0-31, 0 means bit 32
        return true, collision_position
      end

      private

      def communicate_with_picc(command, send_data, rx_align, tx_lastbits)
        wait_irq = 0x00
        wait_irq = 0x10 if command == PCD_MFAuthent
        wait_irq = 0x30 if command == PCD_Transceive

        framing_bit = ((rx_align << 4) & 0x07) & (tx_lastbits & 0x07)

        write_register(CommandReg, PCD_Idle)         # Stop any active command.
        write_register(ComIrqReg, 0x7F)              # Clear all seven interrupt request bits
        set_register_bitmask(FIFOLevelReg, 0x80)     # FlushBuffer = 1, FIFO initialization
        write_register(FIFODataReg, send_data)       # Write sendData to the FIFO
        write_register(BitFramingReg, framing_bit)   # Bit adjustments
        write_register(CommandReg, command)          # Execute the command
        if command == PCD_Transceive
          set_register_bitmask(BitFramingReg, 0x80)  # StartSend=1, transmission of data starts
        end

        # Wait for the command to complete
        i = 2000
        loop do
          irq = read_register(ComIrqReg)
          break if (irq & wait_irq) != 0
          return :status_picc_timeout if (irq & 0x01) != 0
          return :status_pcd_timeout if i == 0
          i -= 1
        end

        # Check for error
        error = read_register(ErrorReg)
        return :status_buffer_overflow if (error & 0x10) != 0
        return :status_crc_error if (error & 0x04) != 0
        return :status_parity_error if (error & 0x02) != 0
        return :status_protocol_error if (error & 0x01) != 0

        # Receiving data
        received_data = []
        data_length = read_register(FIFOLevelReg)
        while data_length > 0 do
          data = read_register(FIFODataReg)
          received_data << data
          data_length -=1
        end
        valid_bits = read_register(ControlReg) & 0x07

        status = :status_ok
        status = :status_collision if (error & 0x08) != 0 # CollErr

        return status, received_data, valid_bits
      end

      def read_register(reg)
        page = (reg >> 4) & 0x0F
        reg = reg & 0x0F
        change_page(page) unless @current_page == page
        super
      end

      def write_register(reg, data)
        page = (reg >> 4) & 0x0F
        reg = reg & 0x0F
        change_page(page) unless reg == PageReg || @current_page == page
        super
      end

      def change_page(page)
        data = 0x80 | (page & 0x03)
        write_register(PageReg, data)
        @current_page = page
      end
    end
  end
end
