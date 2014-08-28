#include <system.h>

// NOTE: this could be more easely done in assembly so we will
// move this part in assembly but atm we do it in C too (just for practice :) )

/*
 * Our gdt descriptor. In assembly 
 * it was declared manually
 */
struct gdt_descriptor
{
    unsigned short limitLow;
    unsigned short baseLow;
    unsigned char baseMiddle;
    unsigned char access;
    unsigned char granularity;
    unsigned char baseHigh;
} __attribute__((packed));

/*
 * Pointer to our structures.
 * base - where it is
 * limit - max bytes taken by GDT - 1
 */
struct gdt_ptr
{
    unsigned short limit;
    unsigned int base;
} __attribute__((packed));

#define GDT_NUMBER 3

/*
 * Three entries same as the bootloader
 */
struct gdt_descriptor gdt[GDT_NUMBER];
struct gdt_ptr gdt_pointer;

/**
 * Function in start.asm.
 */
extern void gdt_flush();

int check_gdt(int num)
{
	if(num >= 0 && num < GDT_NUMBER)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

void set_gdt_gate(int num, unsigned long base, unsigned long limit, unsigned char access, unsigned char granularity)
{
    // NOTE: see table of the GDT in the notebook
    if(check_gdt(num))
	{
	    // Set base
	    gdt[num].baseLow = (base & 0xFFFF);
	    gdt[num].baseMiddle = (base >> 16) & 0xFF;
	    gdt[num].baseHigh = (base >> 24) & 0xFF;
	    
	    // Set limit
	    gdt[num].limitLow = (limit & 0xFFFF);
	    gdt[num].granularity = ((limit >> 16) & 0x0F);
	    
	    // Set granularity
	    gdt[num].granularity |= (granularity & 0xF0);
	    gdt[num].access = access;
	}
}

void gdt_init()
{
    // Set size
    gdt_pointer.limit = (sizeof(struct gdt_descriptor) * 3) - 1;
    // Set it's addres to the address of the gdt
    gdt_pointer.base  = &gdt;
    
    // NULL
    set_gdt_gate(0, 0, 0, 0, 0);
    
    // Code segment
    set_gdt_gate(1, 0, 0xFFFFFFFF, 0x9A, 0xCF);
    
    // Data segment
    set_gdt_gate(2, 0, 0xFFFFFFFF, 0x92, 0xCF);
    
    // Flush out the gdt
    gdt_flush();
}






