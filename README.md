# Fubuki

## Requirements

Linux spidev should be enabled.

For Raspberry Pi, use raspi-config to enable SPI function.

## Usage

### SPI
```Ruby
spi_bus = 0
spi_device = 0

spi = Fubuki::SPI.new(spi_bus, spi_device)

spi_speed = 1_000_000
spi_delay = 10 # usec

spi.transfer([0x01, 0x02, 0x03], spi_speed, spi_delay)
=> [0x10, 0x20, 0x30]

spi.close
```
