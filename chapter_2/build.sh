#!/bin/bash

nasm -o ./mbr.bin ./mbr.S

dd if=./mbr.bin of=/home/hydra/bochs/hd60M.img bs=512 count=1 seek=0 conv=notrunc

rm -rf mbr.bin
