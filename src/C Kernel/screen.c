#include <system.h>

/*
 * A video mem location(16 bits in default mode) is composed
 * of a 3 parts, lower 8 bits for the character to print and
 * 2 upper 4 bit parts that represent the background color and
 * the foreground color
 *  15         12 11         8 7                    0
 *	-------------------------------------------------
 *  | Back Color | Fore Color |       Character     |
 *	-------------------------------------------------
 *
 * Print values/colors:
 * 0 - Black		8  - Dark Gray
 * 1 - Blue			9  - Light Blue
 * 2 - Green		10 - Light Green
 * 3 - Cyan			11 - Light Cyan
 * 4 - Red			12 - Light Red
 * 5 - Magenta		13 - Light Magenta
 * 6 - Brown		14 - Light Brown
 * 7 - Light Gray	15 - White
 */
 
/*
 * Shortcuts for colors :)
 */
#define BLACK 			0
#define BLUE  			1
#define GREEN 			2
#define CYAN  			3	 
#define RED	  			4
#define MAGENTA 		5
#define BROWN			6
#define LIGHT_GRAY		7
#define DARK_GRAY		8
#define LIGHT_BLUE		9
#define	LIGHT_GREEN		10
#define	LIGHT_CYAN		11
#define LIGHT_RED		12
#define LIGHT_MAGENTA	13
#define LIGHT_BROWN		14
#define WHITE			15

/**
 * Default attributes for character printing
 * Black background with white text.
 */
volatile int attribute = GREEN;
 
/**
 * Standard video memory location in default mode.
 * See to change it in BIOS so here we have a more decent resolution.
 */
const unsigned short *videomem = 0xB8000;

/**
 * Standard screen width/height in default mode.
 */
const unsigned int width_of_screen  = 80;
const unsigned int height_of_screen = 25;

/**
 * Current cursor position
 */
int cursor_x = 0, cursor_y = 0;

/**
 * Scrolls up the screen
 */
void scroll() 
{
	unsigned blank, temp;
	
	// Blank
	blank = 0x20 | (attribute << 8);
	
	/*
	 * We scroll by moving ALL the video 
	 * memory a row higher and filling the last row
	 * with blanks
	 */
	 if(cursor_y >= 25)
	 {
		temp = cursor_y - 25 + 1;
		
		// Move the current text chunck back by a line. 
		// (By the way the x2 is because memcpy copies bytes and we need shorts)
		memcpy(videomem, videomem + temp * width_of_screen, (height_of_screen - temp) * width_of_screen * 2);
		
		// Set the last line to blank
		memsetw(videomem + (height_of_screen - temp) * width_of_screen, blank, width_of_screen);
		
		cursor_y = height_of_screen - 1;
	 }
}

void move_cursor(unsigned char x, unsigned char y)
{
	short temp;
	
	// Current index of the position
	temp = y * width_of_screen + x;

	out(0x3D4, 14);
	out(0x3D5, temp >> 8);
	out(0x3D4, 15);
	out(0x3D5, temp);
}

/**
 * Advances the hardware cursor by one unit.
 */
void moveCursor() 
{
	short temp;
	
	// Current index of the position
	temp = cursor_y * width_of_screen + cursor_x;
	
	// Send command to VGA controller
	
	/*
	 * At port 0x3D4 we select the desired register
	 * At port 0x3D5 we send the data to the selected register
	 * Just like the RTC timer from the assembly kernel!
	 */
	
	// Select register 14 from port 0x3D4
	out(0x3D4, 14);
	// Send data to register 14
	out(0x3D5, temp >> 8);
	// Select register 15 from port 0x3D4
	out(0x3D4, 15);
	// Send data to register 15
	out(0x3D5, temp);
}

/**
 * Clears the screen
 */
void cls()
{
	unsigned blank;
	int i;
	
	blank = 0x20 | (attribute << 8);
	
	// Set entire screen to current color
	for(i = 0; i < height_of_screen; i++) 
	{
		memsetw(videomem + i * width_of_screen, blank, width_of_screen);
	}
	
	// Move to origin the cursor
	cursor_x = 0;
	cursor_y = 0;
	
	moveCursor();
}

void putSimbol(unsigned char c, unsigned char x, unsigned char y)
{
	unsigned char *where;
	unsigned att = attribute << 8;

	where = videomem + (y * 80 + x);
    *where = c | att;
}

void putSimbolColor(unsigned char c, unsigned char x, unsigned char y, unsigned char color)
{
	unsigned char *where;

	unsigned att = color << 8;

	where = videomem + (y * 80 + x);
    *where = c | att;
}

/**
 * Put a single character on the screen
 */
void putChar(unsigned char c)
{
	unsigned short *where;
    unsigned att = attribute << 8;

    // Handle a backspace, by moving the cursor back one space
    if(c == 0x08)
    {
        if(cursor_x != 0) cursor_x--;
    }
    // Handles a tab by incrementing the cursor's x, but only
    // to a point that will make it divisible by 8
    else if(c == 0x09)
    {
        cursor_x = (cursor_x + 8) & ~(8 - 1);
    }
	else if(c == '\b')
	{
		cursor_x--;

		where = videomem + (cursor_y * 80 + cursor_x);
        *where = ' ' | att;
	}
    // Handles return
    else if(c == '\r')
    {
        cursor_x = 0;
    }
	// Handler newline
    else if(c == '\n')
    {
        cursor_x = 0;
        cursor_y++;
    }
    // If it's printable print it
    else if(c >= ' ')
    {
		// (Formula for two dim matrix, like where = videomem[cursor_y][cursor_x])
        where = videomem + (cursor_y * 80 + cursor_x);
        *where = c | att;	/* Character AND attributes: color */
        cursor_x++;
    }
	// If cursor got to the edge add a newline
    if(cursor_x >= 80)
    {
        cursor_x = 0;
        cursor_y++;
    }

    // Scroll if needed
    scroll();
	// Move cursor
    moveCursor();
}
 
 /**
  * Puts on the screen a string
  */
void puts(unsigned char *text)
{
	int i;
	int size = strlen(text);
	
	for(i = 0; i < size; i++)
	{
		putChar(text[i]);
	}
}

/**
 * Set the default print color
 */
void setPrintColor(unsigned char bgColor, unsigned char foreColor)
{
	// Also some checks so we don't get junk data
	attribute = (bgColor << 4) | (foreColor & 0x0F);
}

/**
 * Get the index of the position in video memory
 */
int getVidMemIndex(unsigned int x_value, unsigned int y_value) 
{
	// Buffer value is: vidMem[80][25]
	// Since the buffer is linear we need to compute it's value(use the formula y_val * columns + x_val
	return (width_of_screen * y_value) + x_value;
}
