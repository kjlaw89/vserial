# VSerial 1.0.0

VSerial is a simple V package that aims to provide a cross-platform means for working with serial devices. The API is consistent across Windows & Unix systems.

This library is still in early development. This means that it may not work correctly in some instances or even at all on certain platforms.

### Installation

```bash
v install kjlaw89.vserial
```

### Running the examples

The example requires a valid serial port configuration. This can be accomplished with psuedo ports or emulation software. The values for connecting to a port are currently hard-coded in the example.

```bash
cd examples
v run example.v
```

## Example

```v
module main

import serial

fn main() {
	mut conn := serial.open({
		name: "com3"
	})?

	defer { conn.close() }

	conn.write("Hello world!\r\n")
	data := conn.read(255)
	
	println(data)
}
```

## Configuration Options

A config needs to be passed in when initializing a serial connection. Theres are the currently available options:

```go
pub struct Config {
	// name of the port to use (i.e. 'com3' or '/dev/tty2')
	name			string

	// baud rate (default .b9600)
	baud			BaudRate	= .b9600

	// size is the number of bits per byte (default 8)
	size			int 		= 8

	// parity (default .no)
	parity			Parity		= .no

	// number of stop bits to use (default .stop1)
	stop_bits		StopBits	= .stop1
}
```

## Todo

1. Add API call to get a list of available serial devices
2. Expand on the serial options available
	* Hardware / Software Flow control
	* ... to be expanded on ...
3. Automated testing

## License

VSerial is licensed under [MIT](https://choosealicense.com/licenses/mit/).

## Contributing

All contributions are welcome! Please follow the standard Github Pull Request process:

1. Fork it (<https://github.com/kjlaw89/vserial/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
