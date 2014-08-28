#include <system.h>

extern char process_paused;

void command_line();
void get_line();

/**
 * Reads a byte from a specific port
 */
unsigned char in(unsigned short _port)
{
	unsigned char result;
	/*
	 * I don't like this gcc inline stuff, very messy
	 *
	 * Explanation: 
	 * %% - tells us it's a register, if we don't have in/out one % is required
	 * after the first ':' the outputs are ligned up.
	 * "=a" (result) tellls the compiler to put result in EAX. If weed write
	 * "=b" instead then the result is put in EBX, etc...
	 * If we want more that one otput put a ',' and write the next
	 * After the second ':' the inputs. "d" specifies EDX = port. Same as 
	 * output but without the '='. 
	 * Simple :|
	 */
	__asm__ ("in %%dx, %%al" : "=a" (result) : "d" (_port));
	
	return result;
}

/**
 * Writes a byte at a specific port
 */
void out(unsigned short _port, unsigned char _data) 
{
	/*
	 * Same guidelines as the "in".
	 * Here we have only inputs and no output. We can see after the fist ':'
	 * there is a empty space
	 */
	 __asm__ ("out %%al, %%dx" : : "a" (_data), "d" (_port));
}

void worker1()
{
	for(;;)
	{
		puts("Hello from worker 1!\n");
	}
}

void worker2()
{
	for(;;) 
	{
		puts("Hello from worker 2!\n");
	}
}

void kern_main()
{
	for(;;)
	{
		puts("Main process\n");
	}
}

/**
 * Main is void here, not int like standard since this is kernel
 * and we will never return from this main. Anyway who would we 
 * return the int to? Since returning is only a convention...
 */
void main() 
{
	int i;

	// Set the gdt
    gdt_init();
	// Instal IDT
    idt_install();
	// Instal isrs
    isrs_install();
	// Install IRQs
    irq_install();

	// Install timer
	timer_phase(60);
    timer_install();
	// Install keyboard
    keyboard_install();
	
	// Init memory
	memory_init();

	// Init worker
	//workers_init();
	
	// Setup workers
	//worker_init("main", kern_main);
	//worker_init("Worker 1", worker1);
	//worker_init("Worker 2", worker2);

	cls();
    puts("Hello World!\n");

	// Enable interrupts so workers can start working
	__asm__ ("sti");
	
	// Command processing
	command_line();

	// Infinite lup in case we end up here
	for(;;) 
	{
		puts("Main process, waiting keypress...\n");
		wait_key();
	}
}

#define MAX_KEYS 10

// We write after this :)
unsigned char *cmd_spec = "=>>";
unsigned char key_buffer[MAX_KEYS + 1];
unsigned char key_current_pos = 0;

unsigned char minute;

void command_line()
{
	int i;

	puts("Welcome to the command line interpreter!\n");

	char *commands = "Available commands: help, hello, cls, maze, memed, jump, quit\n";
	puts(commands);
	
	while(strcompare(key_buffer, "quit") == 0)
	{
		puts(cmd_spec);

		get_line();

		// Newline after we get the line
		putChar('\n');

		// Parse command
		if(strcompare(key_buffer, "help") == 1)
		{
			puts(commands);
		}
		else if(strcompare(key_buffer, "quit") == 1)
		{
			puts("Quit inserted!\n");
			continue;
		}
		else if(strcompare(key_buffer, "hello") == 1)
		{
			puts("Hello!\n\n");

			unsigned char *message = "Follow the white pheasant...\n";

			for(i = 0; i < strlen(message); i++)
			{
				putChar(message[i]);
				timer_wait(20);
			}
		}
		else if(strcompare(key_buffer, "cls") == 1)
		{
			cls();
		}
		else if(strcompare(key_buffer, "maze") == 1)
		{
			// Pause screen print
			process_paused = 1;

			// Start the game
			maze();

			// Print again
			process_paused = 0;
		}
		else if(strcompare(key_buffer, "memed") == 1)
		{
			process_paused = 1;

			// Memory editor
			memed();

			process_paused = 0;
		}
		else if(strcompare(key_buffer, "jump") == 1)
		{
			puts("Should jump to a certain memory address... work in progress\n");
		}
		else
		{
			puts("Unknown command!\n");
		}

		// Reset key buffer
		key_current_pos = 0;
		for(i = 0; i < MAX_KEYS; i++)
		{
			key_buffer[i] = '\0';
		}
	}

	puts("Command line ended...\n");
}

void get_line()
{
	// Get char from kbd
	unsigned char c;

	do {
		c = get_char();

		// Handles backspace
	    if(c == '\b')
	    {
			if(key_current_pos > 0)
			{
				key_buffer[key_current_pos - 1] = ' ';

				key_current_pos--;
			}
	    }
	    // If it's printable char use it
	    else if(c >= ' ' && key_current_pos < MAX_KEYS)
	    {
			key_buffer[key_current_pos] = c;

			key_current_pos++;

			putChar(c);
	    }
	} while(c != '\n');
}
