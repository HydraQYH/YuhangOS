#!/bin/bash

rm -rf build
mkdir build

# complie print.S
nasm -f elf32 -o build/print.o lib/kernel/print.S

# complie kernel.S
nasm -f elf32 -o build/kernel.o kernel/kernel.S

# complie main.c
gcc -I lib -I lib/kernel -I kernel -m32 -c -fno-builtin -o build/main.o kernel/main.c

# complie interrupt.c
gcc -I lib -I lib/kernel -I kernel -m32 -c -fno-builtin -o build/interrupt.o kernel/interrupt.c

# complie init.c
gcc -I lib -I lib/kernel -I kernel -I device -m32 -c -fno-builtin -o build/init.o kernel/init.c

# complie timer.c
gcc -I lib -I lib/kernel -I kernel -I device -m32 -c -o build/timer.o device/timer.c

# link object files
ld -m elf_i386 -Ttext 0xc0001500 -e main -o build/kernel.bin build/main.o build/init.o build/interrupt.o build/print.o build/kernel.o build/timer.o 

dd if=build/kernel.bin of=/home/hydra/bochs/hd60M.img bs=512 count=200 seek=9 conv=notrunc

rm -rf build
