// The MIT License (MIT)
//
// Copyright (c) 2015 Nick Stevens <nick@bitcurry.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

#![feature(no_std, lang_items)]
#![no_std]

#![allow(non_snake_case)]
#![allow(non_camel_case_types)]

extern crate base64;
#[macro_use] extern crate fixedvec;

use core::slice;
use fixedvec::FixedVec;
use base64::{Base64Encoder, Base64Decoder};

pub type c_char = i8;
pub type size_t = u32;

extern {
    fn strlen(string: *const c_char) -> size_t;
}

#[no_mangle]
pub extern fn c_base64_encode(dst: *mut u8, dstSize: size_t,
                              src: *const u8, srcLength: size_t) -> size_t {
    let src_slice = unsafe {
        slice::from_raw_parts(src, srcLength as usize)
    };

    let mut dst_vec = unsafe {
        FixedVec::new(slice::from_raw_parts_mut(dst, dstSize as usize))
    };

    let encoder = Base64Encoder::new(src_slice);
    dst_vec.extend(encoder);
    dst_vec.push(0).unwrap();
    dst_vec.len() as size_t
}

#[no_mangle]
pub extern fn c_base64_decode(dst: *mut u8, dstSize: size_t,
                              src: *const u8) -> size_t {
    let src_slice = unsafe {
        let len = strlen(src as *const c_char);
        slice::from_raw_parts(src, len as usize)
    };

    let mut dst_vec = unsafe {
        FixedVec::new(slice::from_raw_parts_mut(dst, dstSize as usize))
    };

    let mut decoder = Base64Decoder::new(src_slice);
    while let Some(n) = decoder.next() {
        if dst_vec.push(n).is_err() {
            return 0;
        }
    }

    if decoder.status().is_err() {
        0
    } else {
        dst_vec.len() as size_t
    }
}

#[cfg(not(test))]
#[lang = "eh_personality"]
extern fn eh_personality() { }

#[cfg(not(test))]
#[lang = "panic_fmt"]
extern fn panic_fmt() -> ! {
    loop { }
}
