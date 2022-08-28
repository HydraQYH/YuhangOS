#!/bin/bash

nasm -I /home/hydra/yuhangOS/include/ -o ./mbr.bin ./mbr.S 
dd if=./mbr.bin of=/home/hydra/bochs/hd60M.img bs=512 count=1 seek=0 conv=notrunc
rm -rf mbr.bin

nasm -I /home/hydra/yuhangOS/include/ -o ./loader.bin ./loader2.S
dd if=./loader.bin of=/home/hydra/bochs/hd60M.img bs=512 count=4 seek=2 conv=notrunc
rm -rf loader.bin

gcc -c -m32 -o ./c/kernel/main.o  ./c/kernel/main.c
ld -m elf_i386 ./c/kernel/main.o -Ttext 0xc0001500 -e main -o ./c/kernel/kernel.bin
dd if=./c/kernel/kernel.bin of=/home/hydra/bochs/hd60M.img bs=512 count=200 seek=9 conv=notrunc
rm -rf ./c/kernel/main.o
rm -rf ./c/kernel/kernel.bin
