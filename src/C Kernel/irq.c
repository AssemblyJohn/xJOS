#include <system.h>

/*
 * =================================================
 * Interrupts raised by hardware. We jave to remap these from 32 to 47
 * since the first 31 are already used by exception handlers.
 * =================================================
 */

// IRQ's (declared in the start.asm)

// PIT
extern void irq0();
// Keyboard
extern void irq1();

// Unknown atm :)
extern void irq2();
extern void irq3();
extern void irq4();
extern void irq5();
extern void irq6();
extern void irq7();
extern void irq8();
extern void irq9();
extern void irq10();
extern void irq11();
extern void irq12();
extern void irq13();
extern void irq14();
extern void irq15();

// Numbers of IRQ's
#define IRQ_NUMBER 16

// Number of exceptions. Just to help us
#define EXCEPTION_NUMBER 32

// EOI(End of interrupt)
#define EOI	0x20

// Master and slave ports
#define MASTER 0x20
#define SLAVE  0xA0

// TODO: add multiple listeners to functions with a two dim matrix
void *irq_routines[IRQ_NUMBER] =
{
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0
};

int check_irq(int irq)
{
	// Some basic checks to know if the iqr is valid
	if(irq >= 0 && irq < IRQ_NUMBER)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

/**
 * Installs a IRQ handler for the specified IRQ
 */
void irq_install_handler(int irq, void (*handler)(struct regs *r))
{
	if(check_irq(irq))
	{
 	   irq_routines[irq] = handler;
	}
}

/**
 * Clear IRQ handler
 */
void irq_uninstall_handler(int irq)
{
	if(check_irq(irq))
	{
   		irq_routines[irq] = 0;
	}
}

/**
 * Remaps irqs 0-15 to isrs 32-47
 * inital layout: 0-7 are mapped to isrs 8 - 15 and 8-15 to isrs 70+)
 */
void irq_remap(void)
{
	// TODO: understand this part(look at PIC specifications)
    out(0x20, 0x11);
    out(0xA0, 0x11);
    out(0x21, 0x20); // from 32
    out(0xA1, 0x28);
    out(0x21, 0x04);
    out(0xA1, 0x02);
    out(0x21, 0x01);
    out(0xA1, 0x01);
    out(0x21, 0x0);
    out(0xA1, 0x0);
}

/**
 * We set the gates to the entries just like installing exceptions.
 */
void irq_install()
{
    irq_remap();

    idt_set_gate(32, (unsigned)irq0, 0x08, 0x8E);
    idt_set_gate(33, (unsigned)irq1, 0x08, 0x8E);
    idt_set_gate(34, (unsigned)irq2, 0x08, 0x8E);
    idt_set_gate(35, (unsigned)irq3, 0x08, 0x8E);
    idt_set_gate(36, (unsigned)irq4, 0x08, 0x8E);
    idt_set_gate(37, (unsigned)irq5, 0x08, 0x8E);
    idt_set_gate(38, (unsigned)irq6, 0x08, 0x8E);
    idt_set_gate(39, (unsigned)irq7, 0x08, 0x8E);

    idt_set_gate(40, (unsigned)irq8, 0x08, 0x8E);
    idt_set_gate(41, (unsigned)irq9, 0x08, 0x8E);
    idt_set_gate(42, (unsigned)irq10, 0x08, 0x8E);
    idt_set_gate(43, (unsigned)irq11, 0x08, 0x8E);
    idt_set_gate(44, (unsigned)irq12, 0x08, 0x8E);
    idt_set_gate(45, (unsigned)irq13, 0x08, 0x8E);
    idt_set_gate(46, (unsigned)irq14, 0x08, 0x8E);
    idt_set_gate(47, (unsigned)irq15, 0x08, 0x8E);
}

/**
 * General IRQ handler called from assembly code.
 * After a this has fired we have to tell Interrupt
 * controllers that our work with them is finished.
 * To do so we send them and EOI(End of Interrupt)
 * command. The chips are at ports 0x20(master)
 * and 0xA0(slave). We always have to send the EOI
 * to the master and we have to send an EOI to the
 * slave when we get an interrupt from it. If we do
 * not send the EOI we will not receive any more
 * interrupts.
 */
void irq_handler(struct regs *r)
{
    // Function pointer
    void (*handler)(struct regs *r);

    // See if we have a IRQ handler
    handler = irq_routines[r->int_no - EXCEPTION_NUMBER];

	// If yes send the interrupt
    if (handler)
    {
        handler(r);
    }

    // If the int_no >= 40(it means we got an IRQ from the slave)
    if (r->int_no >= 40)
    {
		// Send the EOI to the slave
        out(SLAVE, EOI);
    }

    // Send the usual EOI to the master
    out(MASTER, EOI);
}










