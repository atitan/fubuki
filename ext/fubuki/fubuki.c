#include <ruby.h>
#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <linux/spi/spidev.h>

static VALUE transfer(int argc, VALUE* argv, VALUE self);

static const char *device = "/dev/spidev0.0";
static uint8_t mode;
static uint8_t bits = 8;
static uint32_t speed = 500000;
static uint16_t delay;

void Init_fubuki(void) {
    VALUE cFubuki = rb_const_get(rb_cObject, rb_intern("Fubuki"));

    VALUE cFubukiSPI = rb_define_module_under(cFubuki, "SPI");
    rb_define_module_function(cFubukiSPI, "transfer", transfer, -1);
}

static VALUE transfer(int argc, VALUE* argv, VALUE self) {
    VALUE tx_data, speed_hz;
    rb_scan_args(argc, argv, "11", &tx_data, &speed_hz);

    int status;
    int fd;

    if (TYPE(tx_data) != T_ARRAY) {
        rb_raise(rb_eTypeError, "input data should be array of bytes");
    }

    fd = open("/dev/spidev0.0", O_RDWR);
    if (fd < 0) {
        rb_raise(rb_eRuntimeError, "cannot open SPI device");
    }

uint8_t tx[] = {
		0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
		0x40, 0x00, 0x00, 0x00, 0x00, 0x95,
		0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
		0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
		0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
		0xDE, 0xAD, 0xBE, 0xEF, 0xBA, 0xAD,
		0xF0, 0x0D,
	};
	uint8_t rx[38] = {0, };
	struct spi_ioc_transfer tr = {
		.tx_buf = (unsigned long)tx,
		.rx_buf = (unsigned long)rx,
		.len = 38,
		.delay_usecs = 0,
		.speed_hz = 1000000,
		.bits_per_word = 8,
	};

	status = ioctl(fd, SPI_IOC_MESSAGE(1), &tr);
	if (status < 1)
        rb_raise(rb_eRuntimeError, "cannot send SPI message");

VALUE rx_data = rb_ary_new2(38);

for (status = 0; status < 38; status++) {
rb_ary_store(rx_data, status, UINT2NUM(rx[status]));
	}

    close(fd);

    return rx_data;
}
