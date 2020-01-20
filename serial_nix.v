module serial

import (
	os
	sync
)

#include <termios.h>

struct Termios {
mut:
	iflag   u32
    oflag   u32
	cflag   u32
    lflag   u32
    line    byte
	cc      [32]byte
    ispeed  u32
    ospeed  u32
}

fn C.tcgetattr(int, byteptr) int 
fn C.tcsetattr(int, int, byteptr) int
fn C.tcflush(int, int) int

// open attempts to connect to the provided serial port
pub fn open(config Config) ?Port {
	if config.name.len == 0 {
		return error("Device name required")
	}

	name := config.name

	file := os.open_file(name, "rc+", 0666) or {
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
	C.tcflush(p.file.fd, C.TCIFLUSH)
}

fn get_baud(baud BaudRate) int {	
	return match baud {
		.b110       { C.B110 }
		.b300       { C.B300 }
		.b600       { C.B600 }
		.b1200      { C.B1200 }
		.b2400      { C.B2400 }
		.b4800      { C.B4800 }
		.b9600      { C.B9600 }
		.b14400     { 0 }
		.b19200     { C.B19200 }
		.b38400     { C.B38400 }
		.b57600     { C.B57600 }
		.b115200    { C.B115200 }
		.b128000    { 0 }
		.b256000    { 0 }
		else        { 0 }
	}
}

fn setup_comm(port mut Port, config Config) ?bool {
	baud := get_baud(config.baud)

	// Base settings
	mut flags := C.CREAD | C.CLOCAL | baud

	// Add in byte size
	match config.size {
		5 { flags |= C.CS5 }
		6 { flags |= C.CS6 }
		7 { flags |= C.CS7 }
		else { flags |= C.CS8 }
	}

	// Add in stop bits (stop1 is default so set to 0)
	match config.stop_bits {
		.stop1 { }
		.stop2 { flags |= C.CSTOPB }
		else {}
	}

	// Add in parity (none is default so set to 0)
	match config.parity {
		.no { }
		.odd { flags |= C.PARENB | C.PARODD }
		.even { flags |= C.PARENB }
		else {}
	}

	mut settings := Termios{
		iflag: 5120
		cflag: flags
		ispeed: baud
		ospeed: baud
	}

	settings.cc[C.VTIME] = 1
	settings.cc[C.VMIN] = 0

	result := C.tcsetattr(port.file.fd, C.TCSANOW, &settings)
	if result == -1 {
		err := C.errno
		return error("Unable to initialize port $err")
	}

	port.flush()
	return true
}