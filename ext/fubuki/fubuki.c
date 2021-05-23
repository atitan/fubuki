#include <ruby.h>
#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <linux/spi/spidev.h>
#include <gpiod.h>

struct spi_malloc {
	int fd;
};

static void spi_alloc_free(void *p);
static VALUE spi_alloc(VALUE klass);
static VALUE spi_init(int argc, VALUE* argv, VALUE self);
static VALUE spi_transfer(int argc, VALUE* argv, VALUE self);
static VALUE spi_close(VALUE self);

static void spi_malloc_free(void *p) {
	struct spi_malloc *ptr = p;

	if (ptr->fd >= 0) {
		close(ptr->fd);
	        ptr->fd = -1;
	}
}

static VALUE spi_alloc(VALUE klass) {
	VALUE obj;
	struct spi_malloc *ptr;

	obj = Data_Make_Struct(klass, struct spi_malloc, NULL, spi_malloc_free, ptr);

	ptr->fd = -1;

	return obj;
}

static VALUE spi_init(int argc, VALUE* argv, VALUE self) {
	VALUE bus, device;
        rb_scan_args(argc, argv, "02", &bus, &device);

	int bus_id = 0;
	switch (TYPE(bus)) {
	case T_FIXNUM:
		bus_id = NUM2UINT(bus);
		break;
	case T_NIL:
		break;
	default:
		rb_raise(rb_eTypeError, "not valid SPI bus id");
		break;
	}

	int device_id = 0;
	switch (TYPE(device)) {
	case T_FIXNUM:
		device_id = NUM2UINT(device);
		break;
	case T_NIL:
		break;
	default:
		rb_raise(rb_eTypeError, "not valid SPI device id");
		break;
	}

	char path[1000] = "";
	snprintf(path, 1000, "/dev/spidev%d.%d", bus_id, device_id);
	int fd = open(path, O_RDWR);
        if (fd < 0) {
                rb_raise(rb_eRuntimeError, "cannot open SPI device");
        }

	struct spi_malloc *ptr;
        Data_Get_Struct(self, struct spi_malloc, ptr);
	ptr->fd = fd;

	return self;
}

static VALUE spi_transfer(int argc, VALUE* argv, VALUE self) {
	char error_message[1000] = "";
        int i = 0;
        int status = 0;

	struct spi_malloc *ptr;
	Data_Get_Struct(self, struct spi_malloc, ptr);
	int fd = ptr->fd;
        if (fd < 0) {
                rb_raise(rb_eRuntimeError, "SPI device not opened");
        }

        VALUE tx_data, speed_hz;
        rb_scan_args(argc, argv, "11", &tx_data, &speed_hz);

        if (TYPE(tx_data) != T_ARRAY) {
                rb_raise(rb_eTypeError, "input data should be array of bytes");
        }

        long buf_len = RARRAY_LEN(tx_data);

        uint8_t *tx_buf = calloc(buf_len, sizeof(uint8_t));
        uint8_t *rx_buf = calloc(buf_len, sizeof(uint8_t));

        for (i = 0; i < buf_len; i++) {
		VALUE element = rb_ary_entry(tx_data, i);
		if (TYPE(element) != T_FIXNUM) {
			snprintf(error_message, 1000, "input data should be array of bytes");
			goto cleanup_buffer;
		}

                tx_buf[i] = (uint8_t)NUM2UINT(element);
        }

        struct spi_ioc_transfer tr = {
                .tx_buf = (unsigned long)tx_buf,
                .rx_buf = (unsigned long)rx_buf,
                .len = buf_len,
                .delay_usecs = 0,
                .speed_hz = 1000000,
                .bits_per_word = 8,
        };

        status = ioctl(fd, SPI_IOC_MESSAGE(1), &tr);

        if (status < 1) {
		snprintf(error_message, 1000, "cannot send SPI message");
		goto cleanup_buffer;
        }

        VALUE rx_data = rb_ary_new2(buf_len);

        for (i = 0; i < buf_len; i++) {
                rb_ary_store(rx_data, i, UINT2NUM(rx_buf[i]));
        }

cleanup_buffer:
        free(tx_buf);
        free(rx_buf);

	if (strlen(error_message) > 0) {
		rb_raise(rb_eRuntimeError, "%s", error_message);
	}

        return rx_data;
}

static VALUE spi_close(VALUE self) {
        struct spi_malloc *ptr;
        Data_Get_Struct(self, struct spi_malloc, ptr);
        int fd = ptr->fd;
        if (fd < 0) {
                rb_raise(rb_eRuntimeError, "SPI device not opened");
        }

	close(fd);

	ptr->fd = -1;

	return Qtrue;
}

void Init_fubuki(void) {
	VALUE cFubuki = rb_const_get(rb_cObject, rb_intern("Fubuki"));

	VALUE cFubukiSPI = rb_define_class_under(cFubuki, "SPI", rb_cObject);
	rb_define_alloc_func(cFubukiSPI, spi_alloc);
	rb_define_method(cFubukiSPI, "initialize", spi_init, -1);
	rb_define_method(cFubukiSPI, "transfer", spi_transfer, -1);
	rb_define_method(cFubukiSPI, "close", spi_close, 0);
}
