#!/bin/bash
# Reassemble Linux kernel source from split parts
cat linux-7.0.12.tar.xz.part* > linux-7.0.12.tar.xz
echo "Linux kernel source reassembled: $(du -h linux-7.0.12.tar.xz | cut -f1)"
