#include <system.h>

// Keyboard shortcuts
#define UP 252
#define DOWN 253

#define MAX_COLUMNS  17
#define MAX_LINES    23
#define BYTES_READ	 391 // (17 * 23)

// How many bytes we move up or down, in our case 17, since it's a whole row
#define MEMORY_DISP  17

// Memory pointer
static unsigned char *mempointer = 0x00000;

// Byte buffer, read BYTES_READ bytes from the offset
static unsigned char byte_buffer[BYTES_READ];

// Read memory into the buffer again from the new location
void read_all();

// Prints again from the new memory offset
void print_all();

// Edit mode
void edit_mode();

void memed()
{
	unsigned char choice;

	cls();

	puts("Welcome to the memory reader!\n\n");

	puts("   --- Controls ---\n\n");
	puts("   Down to navigate through the memory.\n");
	puts("   J to jump to certain address\n");
	puts("   E to enter editor mode\n");
	puts("   C to clear screen\n");
	puts("   Q to quit\n");
	puts("\n\n");
	puts("Press any key to start...");

	wait_key();
	cls();

	// Actual memory editor

	// Move cursor to last position
	move_cursor(0, 24);

	// Make a read and a print
	read_all();
	print_all();

	// Prepare for choice with data
	choice = ' ';

	while(choice != 'q')
	{
		choice = get_char();

		switch(choice)
		{
			case UP:
				mempointer -= MEMORY_DISP;
				read_all();
				print_all();
				break;
			case DOWN:
				mempointer += MEMORY_DISP;
				read_all();
				print_all();
				break;
			case 'e':
				// Editor mode

				break;
			case 'c':
				break;
			case 'j':
				break;
		}
	}

	// Quiting
	cls();
}

void edit_mode()
{
	
}

/**
 * Updates the buffer based on the current address
 */
void read_all()
{
	int i;

	// So we don't ruin the mempointer
	unsigned char *ptr = mempointer;

	// Read BYTES_READ bytes
	for(i = 0; i < BYTES_READ; i++)
	{
		byte_buffer[i] = (*ptr);
		ptr++;
	}
}

/**
 * Should be called after a full read
 */
void print_all()
{
	int i, j, outer;
	char current_column = 0;

	char *hex_nr;

	unsigned char *memptr;
	
	for(outer = 0; outer < MAX_LINES; outer++)
	{
		// Byte buffer displacement in memory displacement
		memptr = (unsigned char *)(((int)byte_buffer) + ((int)(MAX_COLUMNS * outer)));

		// Set current columns to 0
		current_column = 0;

		for(i = 0; i < MAX_COLUMNS; i++)
		{
			hex_nr = get_hex_byte(memptr[i]);

			for(j = 0; j < 2; j++)
			{
				putSimbol(hex_nr[j], current_column, outer);

				// Increment current column after each print
				current_column++;
			}

			// One space after each print
			putSimbol(' ', current_column, outer);

			// Increment current column after each print
			current_column++;
		}

		// Add some spaces until ASCII representation
		for(i = 0; i < 5; i++)
		{
			putSimbol(' ', current_column, outer);

			// Increment current column after each print
			current_column++;
		}

		// After we printed the hex representation print the ASCII one
		for(i = 0; i < MAX_COLUMNS; i++)
		{
			// One space after each print
			putSimbol(memptr[i], current_column, outer);

			// Increment current column after each print
			current_column++;
		}
	}

	// On the last line draw the memory address (line 25)
	unsigned char *str = "Memory address: ";
	unsigned char strstrlen = strlen(str);
	unsigned char last_row = 24;

	for(i = 0; i < strstrlen; i++) 
	{
		putSimbol(str[i], i, last_row);
	}
	
	str = get_number_u((unsigned int)mempointer);
	
	for(i = 0; i < strlen(str) + 14; i++) 
	{
		if(i < strlen(str))
		{
			putSimbol(str[i], i + strstrlen, last_row);
		}
		else
		{
			putSimbol(' ', i + strstrlen, last_row);
		}
	}

	// Else print some ' 's
}
