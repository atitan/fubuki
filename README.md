# Fubuki

Ruby wrapper for Linux spidev driver.

## Requirements

Linux spidev should be enabled.

For Raspberry Pi, use raspi-config to enable SPI function.

## Compatibility

It should work on any Linux environment with required build tools.

However, the author has only tested it on Raspberry Pi 3 running Raspbian Buster(ver 2021-03-04).

## Usage

```Ruby
spi_bus = 0
spi_device = 0

spi = Fubuki::SPI.new(spi_bus, spi_device)

spi_speed = 1_000_000
spi_delay = 10 # usec

response = spi.transfer([0x01, 0x02, 0x03], spi_speed, spi_delay)
=> [0x10, 0x20, 0x30]

spi.close
```
