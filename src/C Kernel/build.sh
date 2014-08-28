nasm -f elf32 -o start.o start.asm

gcc -m32 -Wall -O -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o main.o main.c

gcc -m32 -Wall -O -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o string.o string.c

gcc -m32 -Wall -O -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o gdt.o gdt.c

gcc -m32 -Wall -O -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o idt.o idt.c

gcc -m32 -Wall -O -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o irq.o irq.c

gcc -m32 -Wall -O -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o isrs.o isrs.c

gcc -m32 -Wall -O -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o kybd.o kybd.c

gcc -m32 -Wall -O -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o screen.o screen.c

gcc -m32 -Wall -O -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o timer.o timer.c

gcc -m32 -Wall -O -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o worker.o worker.c

gcc -m32 -Wall -O -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o memory.o memory.c

gcc -m32 -Wall -O -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o random.o random.c

gcc -m32 -Wall -O -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o maze.o maze.c

gcc -m32 -Wall -O -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o memed.o memed.c

./ld -m elf_i386 -z max-page-size=4096 -T link.ld -o xprot.bin start.o main.o string.o gdt.o idt.o irq.o isrs.o kybd.o screen.o timer.o worker.o memory.o random.o maze.o memed.o
