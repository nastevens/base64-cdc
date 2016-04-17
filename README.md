Base64-CDC, or There's Rust in my C
===================================

This is a proof of concept application that demonstrates a few different
things:

  * Writing a Rust library for bare-metal (i.e. without a heap)
  * Integrating a Rust library with a C application using the Foreign Function
    Interface (FFI)
  * Mapping the Rust function to an existing CFL library header file -
    `c_base64` in this case
  * Calling out to Cargo from a Makefile to build the whole solution
  * Running the sucker on a real piece of hardware

For this project, the real piece of hardware is the LPC1768. Since I mainly
wanted to demonstrate Rust/C interaction, I took some shortcuts that I wouldn't
normally take a production project:

  * Support libraries for the mbed platform were compiled on the mbed website
    and then added to version control as binary blobs. That means that only the
    LPC1768 is supported. The actual base64 code is cross platform.
  * The C code has no real bounds checking. I wasn't looking to have a
    production ready application, just a shell to show the Rust integration.

Building and Deploying
----------------------

To build this project you'll need a few things:

  * A Linux computer. Instructions here were used on Ubuntu 14.04.
  * The Rust compiler from the nightly repos. Currently, stable versions of
    Rust do not provide access to the `no_std`, which is needed to disable the
    heap. This will change in the future.
  * A cross-compiled version of Rust's `libcore`
  * The ARM GCC cross compiler

To install the latest Rust nightly run the following command from a terminal:

```bash
$ curl -sSf https://static.rust-lang.org/rustup.sh | sh -s -- --channel=nightly
```

That will install the Rust compiler and the Rust package manager/build system,
Cargo.

Next, you'll need to compile `libcore` for your target architecture. In our
case, we're targeting the LPC1768, so our architecture is `thumbv7m-none-eabi`.
You'll need a couple things to do the compile - a copy of the thumbv7m
architecture config file, and a copy of the `rust-libcore` project:

```sh
# Get the architecture config file. We'll borrow ours from the base64-cdc
# project itself and copy it to the libcore project
$ git clone https://github.com/nastevens/base64-cdc.git
$ git clone https://github.com/hackndev/rust-libcore.git
$ cp base64-cdc/base64-rs-ffi/thumbv7m-none-eabi.json rust-libcore/

# Build our copy of libcore
$ cd rust-libcore
$ cargo build --target=thumbv7m-none-eabi --release
```

You'll then need to make libcore library available to the Rust compiler by
putting it in `/usr/local/lib`:

```sh
$ sudo mkdir -p /usr/local/lib/rustlib/thumbv7m-none-eabi/lib
$ sudo cp target/thumbv7m-none-eabi/release/libcore.rlib /usr/local/lib/rustlib/thumbv7m-none-eabi/lib
```

Now you'll need the GNU ARM Embedded Toolchain:

```sh
$ sudo apt-add-repository ppa:terry.guo/gcc-arm-embedded
$ sudo apt-get update
$ sudo apt-get install gcc-arm-none-eabi
```

Finally, with those tools installed, it's time to build the base64-cdc
application!

```sh
$ cd base64-cdc
$ make
```

Running `make` generates a `.bin` file that can be copied to the LPC1768 using
the drag-and-drop file explorer method, or through OpenOCD or PyOCD. When the
application is running, it will create a USB CDC device on the USB output (pins
31 and 32). Connecting that USB device to a PC and connecting to the serial
port (using miniterm, picoterm, PuTTy, etc) will open the demonstration
interface.

Application
-----------

The application is very simple. Any line that starts with 'e' will be encoded
in base64. Any line that starts with 'd' will be decoded from base64.

The Rust interface presented to the C application is identical to the interface
for `c_base64`. In fact, the exact same header file is used.

Post-Mortem
-----------

The primary gist of this project was learning and answering the question -
could Rust be seamlessly dropped in to replace existing CFL libraries written
in C? The answer, I feel, is both yes and no.

### The Good

Rust itself is a very, very powerful language. It provides an almost
Python-like syntax while still compiling down to machine code. The entire
language has been designed around memory safety. This would be especially
valuable if writing an embedded system that used interrupts (all of them) since
concurrency issues are eliminated.

I also found the level of documentation around the language quite good.
Integrating the Rust code with the C code was not very difficult. Plugging
Cargo in to the Makefile was also straightforward. I see no reason that a Rust
library couldn't be easily used in a C application, or visa versa. The fact
that I was able to directly use the `c_base64` header file, without
modification, was also very positive.

### The Bad

Rust does nothing to prevent writing code that doesn't use a heap. It also does
very little to encourage it. That meant that I was left to implement a lot of
my own solutions for heapless versions of libraries. I ended up producing two
as part of this exercise: [fixedvec](https://github.com/nastevens/fixedvec-rs)
and [base64-noalloc](https://github.com/nastevens/base64-noalloc). `fixedvec`
has been published on [crates.io](https://crates.io), so in this way my
experimentation has contributed to the ecosystem as a whole.

As part of writing heapless code I also found out that there are some
difficulties around using `static` memory in Rust. In embedded C, it is a
well-worn pattern to declare a buffer in static memory for use by a singleton
function. In Rust, this is possible, but requires using the `unsafe` keyword.
This in itself is not bad, and actually, Rust is doing the right thing. It is
unable to reason about the lifetime of a memory space that is accessible to the
entire program at any time. Therefore, it is up to the programmer to
acknowledge that the code they're writing may not be safe for concurrency, and
that acknowledgement takes the form of the `unsafe` keyword. I list this in
"The Bad" only because it is different from C.

### The Ugly

Rust's `libcore` is highly unstable right now, and is practically required for
writing an embedded system. In the instructions above, a cross-compiled version
of `libcore` was placed into `/usr/local/lib`. This is a dirty hack. The
problem is that there is currently no way to install a Rust compiler that has
`libcore` cross-compiled and available for bare-metal applications out of the
box. It is possible to include [rust-libcore](https://github.com/hackndev/rust-libcore)
in a project's `Cargo.toml`, but for that to work all dependencies must also
use `rust-libcore` instead of the built-in `libcore`. Hopefully in the future,
the story for how to leverage `libcore` will be cleaned up.
