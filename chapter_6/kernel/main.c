#include "print.h"

void main(void)
{
    put_str("Yuhang OS Kernel.");
    put_char('\n');
    put_str("Kernel Entry:");
    put_int(0xc0001500);
    put_char('\n');
    put_str("GDT:");
    put_int(0xc0000900);
    put_char('\n');
    put_str("Memory Size:");
    put_int(0xc0000b00);
    put_char('\n');
    put_str("Loader Entry:");
    put_int(0xc0000c00);
    put_char('\n');
    put_str("Kernel Page Table:");
    put_int(0xc0100000);
    put_char('\n');
    put_str("Padding");
    put_char('\n');
    // put_str("Padding");
    // put_char('\n');
    while (1);
}
