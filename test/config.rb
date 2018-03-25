Fubuki.configure do |config|
  config.reader = :mfrc522
  config.default_transceive_timeout = 77.3 # ms

  config.startup = Proc.new do
    # Pull up NRSTPD pin
    PiPiper::Pin.new(pin: 24, direction: :out).on
  end

  config.read_register = Proc.new |register|
    output = nil
    PiPiper::Spi.begin do |spi|
      spi.chip_select_active_low(true)
      spi.bit_order PiPiper::Spi::MSBFIRST
      spi.clock 8000000

      spi.chip_select(PiPiper::Spi::CHIP_SELECT_0) do
        spi.write((register << 1) & 0x7E | 0x80)
        output = spi.read
      end
    end
    output
  end

  config.write_register = Proc.new do |register, data|
    PiPiper::Spi.begin do |spi|
      spi.chip_select_active_low(true)
      spi.bit_order PiPiper::Spi::MSBFIRST
      spi.clock 8000000

      spi.chip_select(PiPiper::Spi::CHIP_SELECT_0) do
        spi.write((register << 1) & 0x7E, *data)
      end
    end
  end
end
