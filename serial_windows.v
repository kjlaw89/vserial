module serial

import (
	os
	sync
)

#flag -lws2_32
#include <winbase.h>

struct DCB {
mut:
	dcb_length		u32
	baud_rate		u32
	flags			[4]byte
	w_reserved		u16
	x_on_lim		u16
	x_off_lim		u16
	byte_size		byte
	parity			byte
	stop_bits		byte
	x_on_char		byte
	x_off_char		byte
	error_char		byte
	eof_char		byte
	evt_char		byte
	w_reserved_1	u16
}

struct Timeouts {
	read_interval_timeout			u32 = u32(10)
	read_total_timeout_multiplier	u32 = u32(0)
	read_total_timeout_constant		u32 = u32(10)
	write_total_timeout_multiplier	u32 = u32(10)
	write_total_timeout_constant	u32 = u32(50)
}

fn C.SetupComm(voidptr, u32, u32) u32
fn C.SetCommState(voidptr, DCB) u32
fn C.SetCommTimeouts(voidptr, Timeouts) u32
fn C.SetCommMask(voidptr, voidptr) u32
fn C.PurgeComm(voidptr, u32) u32

// open attempts to connect to the provided serial port
pub fn open(config Config) ?Port {
	if config.name.len == 0 {
		return error("Device name required")
	}

	name := if config.name[0].str() != "\\" {
		"\\\\.\\" + config.name
	}
	else {
		config.name
	}

	file := os.open_file(name, "r+", 0666) or {
		return error("Unable to open $name")
	}

	mut port := Port{
		name: name
		file: file
		w1: sync.new_mutex()
		r1: sync.new_mutex()
	}

	setup_comm(mut port, config) or {
		return error("Unable to initialize comm port")
	}

	return port
}

pub fn (p mut Port) close() {
	p.file.close()
}

// write attempts to write data to the opened serial port
pub fn (p mut Port) write(data string) {
	p.w1.lock()
	defer { p.w1.unlock() }

	p.file.write(data)
}

pub fn (p mut Port) read(bytes int) ?[]byte {
	p.r1.lock()
	defer { p.r1.unlock() }

	return p.file.read_bytes(bytes)
}

pub fn (p mut Port) flush() {
	handle := C._get_osfhandle(p.file.fd)
	C.PurgeComm(handle, 0x0004) // Purge old TX data
	C.PurgeComm(handle, 0x0008) // Purge old RX data
}

fn get_baud(baud BaudRate) int {
	return match baud {
		.b110		{ 110 }
		.b300		{ 300 }
		.b600		{ 600 }
		.b1200		{ 1200 }
		.b2400		{ 2400 }
		.b4800		{ 4800 }
		.b9600		{ 9600 }
		.b14400		{ 14400 }
		.b19200		{ 19200 }
		.b38400		{ 38400 }
		.b57600		{ 57600 }
		.b115200	{ 115200 }
		.b128000	{ 128000 }
		.b256000	{ 256000 }
		else { 0 }
	}
}

fn setup_comm(port mut Port, config Config) ?bool {

	baud := get_baud(config.baud)

	mut params := DCB{
		dcb_length: sizeof(DCB)
		baud_rate: baud
		byte_size: config.size
		parity: config.parity
		stop_bits: config.stop_bits
	}

	params.flags[0] = byte(0x01|0x10)

	handle := C._get_osfhandle(port.file.fd)
	if C.SetCommState(handle, byteptr(&params)) == 0 {
		error := int(C.GetLastError())
		message := os.get_error_msg(error)
		println("Error1 $error - $message")

		return false
	}

	if C.SetupComm(handle, 64, 64) == 0 {
		error := int(C.GetLastError())
		message := os.get_error_msg(error)
		println("Error2 $error - $message")

		return false
	}

	if C.SetCommTimeouts(handle, byteptr(&Timeouts{})) == 0 {
		error := int(C.GetLastError())
		message := os.get_error_msg(error)
		println("Error3 $error - $message")

		return false
	}

	if C.SetCommMask(handle, &int(0x0001)) == 0 {
		error := int(C.GetLastError())
		message := os.get_error_msg(error)
		println("Error $error - $message")

		return false
	}

	port.flush()
	return true
}