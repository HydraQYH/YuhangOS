BUILD_DIR = ./build
ENTRY_POINT = 0xc0001500
AS = nasm
DD = gcc
LD = ld
LIB = -I lib/ -I lib/kernel/ -I kernel/ -I device/ -I thread/
ASFLAGS = -f elf32
CFLAGS = -Wall $(LIB) -m32 -c -fno-builtin -W -Wstrict-prototypes -Wmissing-prototypes
LDFLAGS = -Ttext $(ENTRY_POINT) -m elf_i386 -e main -Map $(BUILD_DIR)/kernel.map
OBJS = $(BUILD_DIR)/main.o $(BUILD_DIR)/init.o $(BUILD_DIR)/interrupt.o $(BUILD_DIR)/timer.o \
	$(BUILD_DIR)/kernel.o $(BUILD_DIR)/print.o $(BUILD_DIR)/debug.o \
	$(BUILD_DIR)/bitmap.o $(BUILD_DIR)/memory.o $(BUILD_DIR)/string.o \
	$(BUILD_DIR)/thread.o $(BUILD_DIR)/switch.o $(BUILD_DIR)/list.o

$(BUILD_DIR)/main.o: kernel/main.c kernel/init.h lib/kernel/print.h lib/stdint.h kernel/debug.h kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/init.o: kernel/init.c kernel/init.h device/timer.h lib/kernel/print.h lib/stdint.h kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/interrupt.o: kernel/interrupt.c kernel/interrupt.h lib/kernel/print.h lib/stdint.h \
	lib/kernel/io.h kernel/global.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/timer.o: device/timer.c device/timer.h lib/kernel/print.h lib/stdint.h lib/kernel/io.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/debug.o: kernel/debug.c kernel/debug.h lib/kernel/print.h lib/stdint.h kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/string.o: lib/string.c lib/string.h kernel/global.h kernel/debug.h
	$(CC) $(CFLAGS) $< -o $@
 
$(BUILD_DIR)/bitmap.o: lib/kernel/bitmap.c lib/kernel/bitmap.h kernel/global.h lib/stdint.h lib/string.h lib/kernel/print.h kernel/debug.h kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/memory.o: kernel/memory.c kernel/memory.h lib/kernel/bitmap.h lib/stdint.h lib/kernel/print.h kernel/debug.h lib/string.h kernel/global.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/thread.o: thread/thread.c thread/thread.h lib/stdint.h kernel/global.h lib/string.h kernel/memory.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/list.o: lib/kernel/list.c lib/kernel/list.h kernel/global.h lib/stdint.h kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@


$(BUILD_DIR)/kernel.o: kernel/kernel.S
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/print.o: lib/kernel/print.S
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/switch.o: thread/switch.S
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/kernel.bin: $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

.PHONY : mk_dir hd clean all

mk_dir:
	if [[ ! -d $(BUILD_DIR) ]];then mkdir $(BUILD_DIR);fi

hd:
	dd if=$(BUILD_DIR)/kernel.bin of=/home/hydra/bochs/hd60M.img bs=512 count=200 seek=9 conv=notrunc

clean:
	cd $(BUILD_DIR) && rm -f ./*

build: $(BUILD_DIR)/kernel.bin

all: mk_dir build hd

