#ifndef SYSTEM_H
#define SYSTEM_H

/* ISRS.C */
struct regs
{
	unsigned int gs, fs, es, ds;						 // top of stack
    unsigned int edi, esi, ebp, esp, ebx, edx, ecx, eax;
    unsigned int int_no, err_code;
    unsigned int eip, cs, eflags, useresp, ss;    		 // bottom of stack
} __attribute__((packed));

/* MEMORY.C */
extern void memory_init();
extern void *alloc();
extern void free();

/* STRING.C */
extern void print_number(int number);
extern void print_number_u(unsigned int number);
extern char* get_number_u(unsigned int number);
extern char strcompare(const char *str1, const char *str2);
extern void print_hex_byte(unsigned char byte);
extern char* get_hex_byte(unsigned char byte);

/* WORKER.C */
extern void workers_init();
extern void worker_init(char *name, void (*entry)());

/* MAIN.C */
extern void *memcpy(void *dest, const void *src, int count);
extern void *memset(void *dest, char val, int count);
extern unsigned short *memsetw(unsigned short *dest, unsigned short val, int count);
extern int strlen(const char *str);
extern unsigned char in(unsigned short _port);
extern void out(unsigned short _port, unsigned char _data);

/* SCREEN.C */
extern void cls();
extern void move_cursor(unsigned char x, unsigned char y);
extern void puts(unsigned char *text);
extern void putChar(unsigned char c);
extern void putSimbol(unsigned char c, unsigned char x, unsigned char y);
extern void putSimbolColor(unsigned char c, unsigned char x, unsigned char y, unsigned char color);
extern void setPrintColor(unsigned char bgColor, unsigned char foreColor);

/* GDT.C */
extern void set_gdt_gate(int num, unsigned long base, unsigned long limit, unsigned char access, unsigned char gran);
extern void gdt_init();

/* IDT.C */
extern void idt_set_gate(unsigned char num, unsigned long base, unsigned short sel, unsigned char flags);
extern void idt_install();

/* ISRS.C */
extern void isrs_install();

/* IRQ.C */
extern void irq_install_handler(int irq, void (*handler)(struct regs *r));
extern void irq_uninstall_handler(int irq);
extern void irq_install();

/* TIMER.C */
extern void timer_wait(int ticks);
extern void timer_install();
extern void timer_phase(int hz);

/* KEYBOARD.C */
extern void keyboard_install();
extern void wait_key();
extern unsigned char get_char();

/* MAZE.C */
extern void maze();

/* MEMED.C */
extern void memed();

#endif
