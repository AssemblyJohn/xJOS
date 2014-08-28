#include <system.h>

#define UP		252
#define DOWN	253
#define LEFT	254
#define RIGHT	255

/*
 * US keyboard layout
 */
unsigned char kbdus[128] =
{
    0,  27, 
	'1', '2', '3', '4', '5', '6', '7', '8',	'9', '0',
	 '-', '=', '\b', '\t',			/* Tab */
  	'q', 'w', 'e', 'r',	't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',	/* Enter key */
    0, /* 29   - Control */
  	'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';',	/* 39 */
 	'\'', '`',   0,		/* Left shift */
 	'\\', 'z', 'x', 'c', 'v', 'b', 'n',	/* 49 */
  	'm', ',', '.', '/',   0,	/* Right shift */
  	'*',
    0,	/* Alt */
  	' ',	/* Space bar */
    0,	/* Caps lock */
    0,	/* 59 - F1 key ... > */
    0,   0,   0,   0,   0,   0,   0,   0,
    0,	/* < ... F10 */
    0,	/* 69 - Num lock*/
    0,	/* Scroll Lock */
    0,	/* Home key */
    UP,	/* Up Arrow */
    0,	/* Page Up */
  	'-',
    LEFT,	/* Left Arrow */
    0,
    RIGHT,	/* Right Arrow */
  	'+',
    0,	/* 79 - End key*/
    DOWN,	/* Down Arrow */
    0,	/* Page Down */
    0,	/* Insert Key */
    0,	/* Delete Key */
    0,   0,   0,
    0,	/* F11 Key */
    0,	/* F12 Key */
    0,	/* All other keys are undefined */
};	

#undef UP
#undef DOWN
#undef LEFT
#undef RIGHT

#define KEYBOARD_PORT 0x60

volatile char key_wait = 0;
volatile char pause_wait = 0;
unsigned char last_key;

/*
 * Waits a key stroker
 */
void wait_key()
{
	pause_wait = 1;

	while(pause_wait);
}

/**
 * Returns the character from the last keystroke
 */
unsigned char get_char()
{
	key_wait = 1;

	while(key_wait);

	return kbdus[last_key];
}

/**
 * Handles the keyboard interrupt 
 */
void keyboard_handler(struct regs *r)
{
	// TODO:


    unsigned char scancode;

    // Read from the keyboard's data buffer(port 0x60)
    scancode = in(KEYBOARD_PORT);

   	// If top bit is set it means the key has been released
    if (scancode & 0x80)
    {
		// TODO do something usefull with these
    }
    else
    {
		// Updates last key
		last_key = scancode;

		// Stops waiting
		key_wait = 0;

		pause_wait = 0;

		// Removed
        // Put the char readed 
        // putChar(kbdus[scancode]);
    }

}

/* Installs the keyboard handler into IRQ1 */
void keyboard_install()
{
    irq_install_handler(1, keyboard_handler);
}


