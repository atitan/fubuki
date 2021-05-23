# Fubuki


## Requirements

libgpiod-dev

## Usage

### SPI
```Ruby
spi_bus = 0
spi_device = 0

spi = Fubuki::SPI.new(spi_bus, spi_device)

spi.transfer([0x01, 0x02, 0x03])
=> [0x10, 0x20, 0x30]

spi.close
```

### GPIO
```Ruby
Fubuki::GPIO
```
