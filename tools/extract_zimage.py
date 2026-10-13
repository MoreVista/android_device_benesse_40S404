#!/usr/bin/env python3
"""Extract the kernel (zImage) from an Android boot.img / recovery.img.

The device trees in this repository do not ship the kernel binary. Dump your
own boot partition (p1) and run:

    python3 tools/extract_zimage.py boot.img prebuilt/zImage

The kernel in your boot.img and recovery.img is the same binary on these units.
Compare the printed md5 with the value in README.md to confirm you have the
same build.
"""
import hashlib
import os
import struct
import sys


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    src, dst = argv[1], argv[2]
    with open(src, "rb") as f:
        data = f.read()
    if data[:8] != b"ANDROID!":
        print("error: not an Android boot image (missing ANDROID! magic)")
        return 1
    kernel_size, kernel_addr, ramdisk_size, ramdisk_addr = struct.unpack("<4I", data[8:24])
    page_size = struct.unpack("<I", data[36:40])[0]
    if page_size not in (2048, 4096, 8192, 16384):
        print("error: unexpected page size %d" % page_size)
        return 1
    kernel = data[page_size:page_size + kernel_size]
    if len(kernel) != kernel_size:
        print("error: image is truncated")
        return 1
    if kernel[0x24:0x28] != bytes.fromhex("18286f01"):
        print("warning: no ARM zImage magic at offset 0x24")
    os.makedirs(os.path.dirname(os.path.abspath(dst)), exist_ok=True)
    with open(dst, "wb") as f:
        f.write(kernel)
    print("kernel: %d bytes, load address %#x" % (kernel_size, kernel_addr))
    print("md5:    %s" % hashlib.md5(kernel).hexdigest())
    print("wrote:  %s" % dst)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
