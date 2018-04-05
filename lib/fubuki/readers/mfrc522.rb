require 'fubuki/reader'

module Fubuki
  module Readers
    class MFRC522 < Reader
      # PCD commands
      PCD_Idle          = 0x00  # no action, cancels current command execution
      PCD_Mem           = 0x01  # stores 25 bytes into the internal buffer
      PCD_GenRandomID   = 0x02  # generates a 10-byte random ID number
      PCD_CalcCRC       = 0x03  # activates the CRC coprocessor or performs a self test
      PCD_Transmit      = 0x04  # transmits data from the FIFO buffer
      PCD_NoCmdChange   = 0x07  # no command change, can be used to modify the CommandReg register bits without affecting the command, for example, the PowerDown bit
      PCD_Receive       = 0x08  # activates the receiver circuits
      PCD_Transceive    = 0x0C  # transmits data from FIFO buffer to antenna and automatically activates the receiver after transmission
      PCD_MFAuthent     = 0x0E  # performs the MIFARE standard authentication as a reader
      PCD_SoftReset     = 0x0F  # resets the MFRC522

      # Command and Status Registers
      CommandReg        = 0x01  # starts and stops command execution
      ComIEnReg         = 0x02  # enable and disable interrupt request control bits
      DivIEnReg         = 0x03  # enable and disable interrupt request control bits
      ComIrqReg         = 0x04  # interrupt request bits
      DivIrqReg         = 0x05  # interrupt request bits
      ErrorReg          = 0x06  # error bits showing the error status of the last command executed 
      Status1Reg        = 0x07  # communication status bits
      Status2Reg        = 0x08  # receiver and transmitter status bits
      FIFODataReg       = 0x09  # input and output of 64 byte FIFO buffer
      FIFOLevelReg      = 0x0A  # number of bytes stored in the FIFO buffer
      WaterLevelReg     = 0x0B  # level for FIFO underflow and overflow warning
      ControlReg        = 0x0C  # miscellaneous control registers
      BitFramingReg     = 0x0D  # adjustments for bit-oriented frames
      CollReg           = 0x0E  # bit position of the first bit-collision detected on the RF interface

      # Command Registers
      ModeReg           = 0x11  # defines general modes for transmitting and receiving 
      TxModeReg         = 0x12  # defines transmission data rate and framing
      RxModeReg         = 0x13  # defines reception data rate and framing
      TxControlReg      = 0x14  # controls the logical behavior of the antenna driver pins TX1 and TX2
      TxASKReg          = 0x15  # controls the setting of the transmission modulation
      TxSelReg          = 0x16  # selects the internal sources for the antenna driver
      RxSelReg          = 0x17  # selects internal receiver settings
      RxThresholdReg    = 0x18  # selects thresholds for the bit decoder
      DemodReg          = 0x19  # defines demodulator settings
      MfTxReg           = 0x1C  # controls some MIFARE communication transmit parameters
      MfRxReg           = 0x1D  # controls some MIFARE communication receive parameters
      SerialSpeedReg    = 0x1F  # selects the speed of the serial UART interface

      # Configuration Registers
      CRCResultRegH     = 0x21  # shows the MSB and LSB values of the CRC calculation
      CRCResultRegL     = 0x22
      ModWidthReg       = 0x24  # controls the ModWidth setting?
      RFCfgReg          = 0x26  # configures the receiver gain
      GsNReg            = 0x27  # selects the conductance of the antenna driver pins TX1 and TX2 for modulation 
      CWGsPReg          = 0x28  # defines the conductance of the p-driver output during periods of no modulation
      ModGsPReg         = 0x29  # defines the conductance of the p-driver output during periods of modulation
      TModeReg          = 0x2A  # defines settings for the internal timer
      TPrescalerReg     = 0x2B  # the lower 8 bits of the TPrescaler value. The 4 high bits are in TModeReg.
      TReloadRegH       = 0x2C  # defines the 16-bit timer reload value
      TReloadRegL       = 0x2D
      TCounterValueRegH = 0x2E  # shows the 16-bit timer value
      TCounterValueRegL = 0x2F

      # Test Registers
      TestSel1Reg       = 0x31  # general test signal configuration
      TestSel2Reg       = 0x32  # general test signal configuration
      TestPinEnReg      = 0x33  # enables pin output driver on pins D1 to D7
      TestPinValueReg   = 0x34  # defines the values for D1 to D7 when it is used as an I/O bus
      TestBusReg        = 0x35  # shows the status of the internal test bus
      AutoTestReg       = 0x36  # controls the digital self test
      VersionReg        = 0x37  # shows the software version
      AnalogTestReg     = 0x38  # controls the pins AUX1 and AUX2
      TestDAC1Reg       = 0x39  # defines the test value for TestDAC1
      TestDAC2Reg       = 0x3A  # defines the test value for TestDAC2
      TestADCReg        = 0x3B  # shows the value of ADC I and Q channels

      spec :protocol, [:a, :mifare]
      spec :baud_rate, [106, 212, 424, 848]
      spec :buffer_size, 64

      def soft_reset
        write_register(CommandReg, PCD_SoftReset)
        sleep 0.05 # wait 50ms

        write_register(TModeReg, 0x87) # Start timer by setting TAuto=1, and higher part of TPrescalerReg
        write_register(TPrescalerReg, 0xFF) # Set lower part of TPrescalerReg, and results in 302us timer (f_timer = 13.56 MHz / (2*TPreScaler+1))
        
        write_register(TxASKReg, 0x40) # Default 0x00. Force a 100 % ASK modulation independent of the ModGsPReg register setting
      end

      # Reset PCD config to default
      def config_reset
        # Stop current command
        write_register(CommandReg, PCD_Idle)

        # Stop crypto1 communication
        mifare_deauthenticate

        # Clear ValuesAfterColl bit
        clear_register_bitmask(CollReg, 0x80)

        # Reset transceiver baud rate to 106 kBd
        transceiver_baud_rate(:tx, 106)
        transceiver_baud_rate(:rx, 106)

        # Set PCD timer value for 302us default timer
        # 256 ticks = 77.4ms
        internal_timer(256)
      end

      # Control transceive timeout value
      def internal_timer(timer = nil)
        if timer
          write_register(TReloadRegH, (timer >> 8) & 0xFF)
          write_register(TReloadRegL, (timer & 0xFF))
        end
        (read_register(TReloadRegH) << 8) | read_register(TReloadRegL)
      end

      # Control transceiver baud rate
      # value = 0: 106kBd, 1: 212kBd, 2: 424kBd, 3: 848kBd
      def transceiver_baud_rate(direction, value = nil)
        reg = {tx: TxModeReg, rx: RxModeReg}
        speed = {106 => 0, 212 => 1, 424 => 2, 848 => 3}
        mod = {0 => 0x26, 1 => 0x15, 2 => 0x0A, 3 => 0x05}

        if value
          value = speed.fetch(value)
          @built_in_crc_disabled = (value == 0)
          write_register(ModWidthReg, mod.fetch(value))
          value <<= 4
          value |= 0x80 unless @built_in_crc_disabled
          write_register(reg.fetch(direction), value)
        end

        (read_register(reg.fetch(direction)) >> 4) & 0x07
      end

      # Turn antenna on
      def antenna_on
        set_register_bitmask(TxControlReg, 0x03)
      end

      # Turn antenna off
      def antenna_off
        clear_register_bitmask(TxControlReg, 0x03)
      end

      # Start Crypto1 communication between reader and Mifare PICC
      #
      # PICC must be selected before calling for authentication
      # Remember to deauthenticate after communication, or no new communication can be made
      #
      # Accept PICC_MF_AUTH_KEY_A or PICC_MF_AUTH_KEY_B command
      # Checks datasheets for block address numbering of your PICC
      #
      def mifare_authenticate(command, block_addr, sector_key, uid)
        # Buffer[12]: {command, block_addr, sector_key[6], uid[4]}
        buffer = [command, block_addr]
        buffer.concat(sector_key[0..5])
        buffer.concat(uid[0..3])

        communicate_with_picc(PCD_MFAuthent, buffer)

        # Check MFCrypto1On bit
        (read_register(Status2Reg) & 0x08) != 0
      end

      # Stop Crypto1 communication
      def mifare_deauthenticate
        clear_register_bitmask(Status2Reg, 0x08) # Clear MFCrypto1On bit
      end

      # Append CRC to buffer and check CRC or Mifare acknowledge
      def transceive(protocol, send_data, crc: true, framing_bit: 0)
        unless crc || @built_in_crc_disabled
          raise UsageError, 'Built-in CRC enabled while CRC is not wanted'
        end

        if send_data.is_a?(Array)
          send_data = send_data.dup
        else
          send_data = [send_data]
        end
        send_data.append_crc16(protocol) if @built_in_crc_disabled && crc

        puts "Sending Data: #{send_data.to_bytehex}" if ENV['DEBUG']

        # Transfer data
        status, received_data, valid_bits = communicate_with_picc(PCD_Transceive, send_data, framing_bit)
        return status, received_data, valid_bits if status != :status_ok

        puts "Received Data: #{received_data.to_bytehex}" if ENV['DEBUG']
        puts "Valid bits: #{valid_bits}" if ENV['DEBUG']

        # Data exists, check CRC
        if received_data.size > 2 && @built_in_crc_disabled && crc
          raise IncorrectCRCError unless received_data.check_crc16(protocol, true)
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

      def communicate_with_picc(command, send_data, framing_bit)
        wait_irq = 0x00
        wait_irq = 0x10 if command == PCD_MFAuthent
        wait_irq = 0x30 if command == PCD_Transceive

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
    end
  end
end
