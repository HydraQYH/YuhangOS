#!/bin/bash

# complie print.S
nasm -f elf32 -o lib/kernel/print.o lib/kernel/print.S

# complie main.c
gcc -I lib -I lib/kernel -m32 -c -o kernel/main.o kernel/main.c

# linked main.o & print.o
ld -m elf_i386 -Ttext 0xc0001500 -e main -o kernel.bin kernel/main.o lib/kernel/print.o

dd if=kernel.bin of=/home/hydra/bochs/hd60M.img bs=512 count=200 seek=9 conv=notrunc

rm -rf lib/kernel/print.o
rm -rf kernel/main.o
rm -rf kernel.bin

