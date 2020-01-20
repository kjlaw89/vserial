/*
V-Serialport is a basic module to that allows you to interact with serial
ports as a stream of bytes with a consistent API across all operating systems.
*/

module serial

pub enum BaudRate {
	b110
	b300
	b600
	b1200
	b2400
	b4800
	b9600
	b14400
	b19200
	b38400
	b57600
	b115200
	b128000
	b256000
}

pub enum Parity {
	no		= 0
	odd		= 1
	even	= 2
	mark	= 3
	space	= 4
}

pub enum StopBits {
	stop1		= 0
	stop1half	= 1
	stop2		= 2
}

// Config contains the details for connecting and interacting with the serial port.
// name is required, the remaining values are configured for most use cases (9600-N-8-1)
pub struct Config {
	// name of the port to use (i.e. 'com3' or '/dev/tty2')
	name			string

	// baud rate (default .b9600)
	baud			BaudRate	= BaudRate.b9600

	// size is the number of bits per byte (default 8)
	size			int 		= 8

	// parity (default .no)
	parity			Parity		= Parity.no

	// number of stop bits to use (default .stop1)
	stop_bits		StopBits	= StopBits.stop1
}

// Port wraps the File object used for communicating with a serial port
pub struct Port {
	w1		sync.Mutex
	r1		sync.Mutex
pub:
	name	string
	file 	os.File	
}