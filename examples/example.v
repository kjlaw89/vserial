module main

import serial

fn main() {
	mut conn := serial.open({
		name: "com3"	// use /dev/ttyX for Unix systems
	})?

	defer { conn.close() }

	conn.write("Testing serial!!!\r\n")
	for i := 1; i < 11; i++ {
		conn.write("Line $i!\r\n")
	}

	for {
		data := conn.read(255) or {
			continue
		}

		for d in data {
			if d == 27 {
				return
			}

			print(d.str())
		}
	}
}