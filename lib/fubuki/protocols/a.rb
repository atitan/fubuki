module Fubuki
  module Protocols
    module A
      extend self

      # PICC commands used by the PCD to manage communication with several PICCs (ISO 14443-3, Type A, section 6.4)
      PICC_REQA         = 0x26  # REQuest command, Type A. Invites PICCs in state IDLE to go to READY and prepare for anticollision or selection. 7 bit frame.
      PICC_WUPA         = 0x52  # Wake-UP command, Type A. Invites PICCs in state IDLE and HALT to go to READY(*) and prepare for anticollision or selection. 7 bit frame.
      PICC_CT           = 0x88  # Cascade Tag. Not really a command, but used during anti collision.
      PICC_SEL_CL1      = 0x93  # Anti collision/Select, Cascade Level 1
      PICC_SEL_CL2      = 0x95  # Anti collision/Select, Cascade Level 2
      PICC_SEL_CL3      = 0x97  # Anti collision/Select, Cascade Level 3
      PICC_HLTA         = 0x50  # HaLT command, Type A. Instructs an ACTIVE PICC to go to state HALT.

      def transceive(data, *args)
        Fubuki.reader.transceive(data, *args)
      end

      def request(wakeup = false)
        Fubuki.reader.config_reset

        command = wakeup ? PICC_WUPA : PICC_REQA
        status, received_data, valid_bits = transceive(command, crc: false, tx_lastbits: 7)

        # REQA or WUPA command return 16 bits(full byte)
        return false unless status == :status_ok && valid_bits == 0

        received_data
      end

      def wakeup
        request(true)
      end

      def halt
        status, _received_data, _valid_bits = transceive([PICC_HLTA, 0])

        # PICC in HALT state will not respond
        # If PICC sent reply, means it didn't acknowledge the command we sent
        status == :status_picc_timeout
      end

      # Select PICC for further communication
      #
      # PICC must be in state ACTIVE
      def select(disable_anti_collision: false)
        #  Description of buffer structure:
        #
        #  Byte 0: SEL   Indicates the Cascade Level: PICC_CMD_SEL_CL1, PICC_CMD_SEL_CL2 or PICC_CMD_SEL_CL3
        #  Byte 1: NVB   Number of Valid Bits (in complete command, not just the UID): High nibble: complete bytes, Low nibble: Extra bits. 
        #  Byte 2: UID-data or Cascade Tag
        #  Byte 3: UID-data
        #  Byte 4: UID-data
        #  Byte 5: UID-data
        #  Byte 6: Block Check Character - XOR of bytes 2-5
        #  Byte 7: CRC_A
        #  Byte 8: CRC_A
        #  The BCC and CRC_A are only transmitted if we know all the UID bits of the current Cascade Level.
        #
        #  Description of bytes 2-5
        #
        #  UID size  Cascade level Byte2 Byte3 Byte4 Byte5
        #  ========  ============= ===== ===== ===== =====
        #   4 bytes        1       uid0  uid1  uid2  uid3
        #   7 bytes        1       CT    uid0  uid1  uid2
        #                  2       uid3  uid4  uid5  uid6
        #  10 bytes        1       CT    uid0  uid1  uid2
        #                  2       CT    uid3  uid4  uid5
        #                  3       uid6  uid7  uid8  uid9
        Fubuki.reader.config_reset

        cascade_levels = [PICC_SEL_CL1, PICC_SEL_CL2, PICC_SEL_CL3]
        uid = []
        sak = 0

        cascade_levels.each do |cascade_level|
          buffer = [cascade_level]
          current_level_known_bits = 0
          received_data = []
          valid_bits = 0
          timeout = true

          # Maxmimum loop count is defined in ISO spec
          32.times do
            if current_level_known_bits >= 32 # Prepare to do a complete select if we knew everything
              # Validate buffer content against non-numeric classes and incorrect size
              buffer = buffer[0..5]
              dirty_buffer = buffer.size != 6
              dirty_buffer ||= buffer.any? {|byte| !byte.is_a?(Integer) }

              # Retry reading UID when buffer is dirty, but don't reset loop count to prevent infinite loop
              if dirty_buffer
                # Reinitialize all variables
                buffer = [cascade_level]
                current_level_known_bits = 0
                received_data = []
                valid_bits = 0

                # Continue to next loop
                next
              end

              tx_last_bits = 0
              buffer[1] = 0x70 # NVB - We're sending full length byte[0..6]
              buffer[6] = (buffer[2] ^ buffer[3] ^ buffer[4] ^ buffer[5]) # Block Check Character

              # Append CRC to buffer
              buffer.append_crc16(:a)
            else
              tx_last_bits = current_level_known_bits % 8
              uid_full_byte = current_level_known_bits / 8
              all_full_byte = 2 + uid_full_byte # length of SEL + NVB + UID
              buffer[1] = (all_full_byte << 4) + tx_last_bits # NVB

              buffer_length = all_full_byte + (tx_last_bits > 0 ? 1 : 0)
              buffer = buffer[0...buffer_length]
            end

            # Select it
            status, received_data, valid_bits = transceive(buffer, crc: false, rx_align: tx_last_bits, tx_lastbits: tx_last_bits)

            if status != :status_ok && status != :status_collision
              raise CommunicationError, status
            elsif status == :status_collision && disable_anti_collision
              raise CollisionError
            end

            if received_data.empty?
              raise UnexpectedDataError, 'Received empty UID data'
            end

            # Append received UID into buffer if not doing full select
            if current_level_known_bits < 32
              # Check for last collision
              if tx_last_bits != 0
                buffer[-1] |= received_data.shift
              end

              buffer += received_data
            end

            # Handle collision
            if status == :status_collision
              collided, collision_position = Fubuki.reader.collision_detail

              # CollPosNotValid - We don't know where collision happened
              raise CollisionError unless collided
              raise CollisionError if collision_position <= current_level_known_bits

              # Calculate position
              current_level_known_bits = collision_position
              uid_bit = (current_level_known_bits - 1) % 8

              # Mark the collision bit
              buffer[-1] |= (1 << uid_bit)
            else
              if current_level_known_bits >= 32
                timeout = false
                break
              end
              current_level_known_bits = 32 # We've already known all bits, loop again for a complete select
            end 
          end

          # Handle timeout after 32 loops
          if timeout
            raise UnexpectedDataError, 'Keep receiving incomplete UID until timeout'
          end

          # We've finished current cascade level
          # Check and collect all uid stored in buffer

          # Append UID
          uid << buffer[2] if buffer[2] != PICC_CT
          uid << buffer[3] << buffer[4] << buffer[5]

          # Check the result of full select
          # Select Acknowledge is 1 byte + CRC16
          raise UnexpectedDataError, 'Unknown SAK format' if received_data.size != 3 || valid_bits != 0 
          raise IncorrectCRCError unless received_data.check_crc16(:a, true)

          sak = received_data[0]
          break if (sak & 0x04) == 0 # No more cascade level
        end

        return uid, sak
      end
    end
  end
end
