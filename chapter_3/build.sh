#!/bin/bash

# nasm -o ./mbr.bin ./mbr.S
nasm -I /home/hydra/yuhangOS/include/ -o ./mbr.bin ./mbr2.S 
dd if=./mbr.bin of=/home/hydra/bochs/hd60M.img bs=512 count=1 seek=0 conv=notrunc
rm -rf mbr.bin

nasm -I /home/hydra/yuhangOS/include/ -o ./loader.bin ./loader.S
dd if=./loader.bin of=/home/hydra/bochs/hd60M.img bs=512 count=4 seek=2 conv=notrunc
rm -rf loader.bin

