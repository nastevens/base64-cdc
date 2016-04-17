/**
 * Demonstration program showing a C++ program running an external Rust library
 * on bare metal.  Note that the C++ program is just a shell for this proof of
 * concept. As such, it has ALMOST NO ERROR CHECKING. If you write code like
 * this for production, your mother will cry. Don't make your mother cry, you
 * monster.
 */

#include "mbed.h"
#include "USBSerial.h"

extern "C" {
#include "c_base64.h"
}

/* Virtual serial port over USB */
USBSerial serial;

/**
 * Blocking function to read until a newline is received. Does no error
 * checking - buffer overflowing this program would be super easy
 */
size_t read_to_newline(USBSerial *serial, char* buffer) {
    char c;
    size_t cnt = 0;

    while (1) {
        c = serial->getc();
        if (c == '\n' || c == '\r') {
            return cnt;
        } else {
            buffer[cnt++] = c;
        }
    }
}

int main(void)
{
    char input[128];
    char command;
    char output[128];
    size_t len;

    while(1) {
        command = serial.getc();
        if (command == 'd') {
            len = read_to_newline(&serial, input);
            input[len] = '\0';
            len = c_base64_decode((uint8_t*)output, sizeof output, input);
            if (len == 0) {
                serial.puts("Error\r\n");
            } else {
                /* Output is not guaranteed to be a string, so we can't rely on
                 * a final NULL byte */
                for (size_t i = 0; i < len; i++) {
                    serial.putc(output[i]);
                }
                serial.puts("\r\n");
            }
        } else if (command == 'e') {
            len = read_to_newline(&serial, input);
            c_base64_encode(output, sizeof output, (uint8_t*)input, len);
            serial.printf("%s\r\n", output);
        } else {
            serial.puts("First character must be (d)ecode or (e)ncode\r\n");
        }
    }
}
