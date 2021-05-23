# frozen_string_literal: true

require 'mkmf'

REQUIRED_HEADER = %w[
  ruby.h
  stdio.h
  stdlib.h
  stdint.h
  string.h
  errno.h
  fcntl.h
  unistd.h
  sys/ioctl.h
  linux/types.h
  linux/spi/spidev.h
  gpiod.h
].freeze

REQUIRED_HEADER.each do |header|
  abort "missing header: #{header}" unless have_header header
end

create_makefile 'fubuki/fubuki'
