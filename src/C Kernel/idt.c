#include <system.h>

/*
 * =================================================
 * IDT are for ISR's and for interrupt(INTs, IRQs). 
 * Basically same as the IVT in the real mode.
 * =================================================
 */


/*
 * IDT table entry. Similar to GDT.
 */
struct idt_entry
{
    unsigned short base_lo;
    unsigned short sel;        /* Our kernel segment goes here! */
    unsigned char always0;     /* This will ALWAYS be set to 0! */
    unsigned char flags;      
    unsigned short base_hi;
} __attribute__((packed));

/*
 * Somehow like the gdt pointer
 */
struct idt_ptr
{
    unsigned short limit;
    unsigned int base;
} __attribute__((packed));

/*
 * Has 256 entries, some reserved by Intel
 */
struct idt_entry idt[256];
struct idt_ptr idtp;

/**
 * In start.asm we will use it after we do the inits
 */
extern void _idt_load();

/**
 * Set a IDT gate
 */
void idt_set_gate(unsigned char num, unsigned long base, unsigned short sel, unsigned char flags)
{
    // The interrupt routine's base address
    idt[num].base_lo = (base & 0xFFFF);
    idt[num].base_hi = (base >> 16) & 0xFFFF;
    
	// Selector (usually 0x08, kernel code selector)
    idt[num].sel = sel;
    idt[num].always0 = 0;

	// Flags
    idt[num].flags = flags;
}

/**
 * Installs the IDT 
 */
void idt_install()
{
	// Sets the special pointer
    idtp.limit = (sizeof (struct idt_entry) * 256) - 1;
    idtp.base = &idt;
    
    // Clear the idt
    memset(&idt, 0, sizeof(struct idt_entry) * 256);
    
    // Call the assembly function
    _idt_load();
}
