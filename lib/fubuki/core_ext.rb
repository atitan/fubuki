class Array
  def append_uint(number, byte)
    raise ArgumentError, 'Only support unsigned integer' if number < 0
    raise ArgumentError, 'Insufficient bytes' if number.abs >= (1 << (byte * 8))

    until byte == 0
      self << (number & 0xFF)
      number >>= 8
      byte -= 1
    end
    self
  end

  def to_uint
    int = 0
    self.each_with_index do |byte, index|
      int |= (byte << (index * 8))
    end
    int
  end

  def append_sint(number, byte)
    raise ArgumentError, 'Insufficient bytes' if number.abs >= (1 << (byte * 8))

    sign = (number < 0) ? 1 : 0
    number &= (1 << ((byte * 8) - 1)) - 1
    self.append_uint(number, byte)
    self << (self.pop | (sign << 7))
  end

  def to_sint
    sign = (self.last & 0x80 != 0) ? (-1 ^ ((1 << ((self.size * 8) - 1)) - 1)) : 0
    sign | self.to_uint
  end

  def append_crc16(type)
    append_uint(crc16(type), 2)
  end

  def append_crc32
    append_uint(crc32, 4)
  end

  def check_crc16(type, remove_after_check = false)
    orig_crc = pop(2)
    new_crc = [].append_uint(crc16(type), 2)
    concat(orig_crc) unless remove_after_check
    orig_crc == new_crc
  end

  def check_crc32(remove_after_check = false)
    orig_crc = pop(4)
    new_crc = [].append_uint(crc32, 4)
    concat(orig_crc) unless remove_after_check
    orig_crc == new_crc
  end

  def xor(array2)
    zip(array2).map{|x, y| x ^ y }
  end

  def to_bytehex
    map{ |x| x.to_bytehex }
  end

  private

  def crc16(type)
    case type
    when :a, :b
      iso_crc16(type)
    when :felica
      felica_crc16
    else
      raise UsageError, 'Unknown CRC16 type'
    end
  end

  def iso_crc16(type)
    crc = (type == :a) ? 0x6363 : 0xFFFF
    self.each do |byte|
      bb = (byte ^ crc) & 0xFF
      bb = (bb ^ (bb << 4)) & 0xFF
      crc = (crc >> 8) ^ (bb << 8) ^ (bb << 3) ^ (bb >> 4)
    end
    crc = ~crc if type == :b
    crc & 0xFFFF
  end

  def felica_crc16
    crc = 0x0000
    self.each do |byte|
      v = 0x80
      until v == 0 do
        flag = crc & 0x8000 != 0
        crc <<= 1
        crc += 1 if byte & v != 0
        crc ^= 0x1021 if flag
        v >>= 1
      end
    end
    crc & 0xFFFF
  end

  def crc32
    crc = 0xFFFFFFFF
    self.each do |byte|
      crc ^= byte
      8.times do
        flag = crc & 0x01 != 0
        crc >>= 1
        crc ^= 0xEDB88320 if flag
      end
    end
    crc
  end
end

class Numeric
  def to_bytehex
    self.to_s(16).rjust(2, '0').upcase
  end
end
