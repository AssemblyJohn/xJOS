#include <system.h>
#include <random.h>

#define UP		252
#define DOWN	253
#define LEFT	254
#define RIGHT	255

const unsigned int width_s  = 80;
const unsigned int height_s = 25;

char actor_x;
char actor_y;

char dest_x;
char dest_y;

char board[80][25];

/**
 * Draws the board
 */
void draw_board()
{
	int i, j;

	for(i = 0; i < width_s; i++)
	{
		for(j = 0; j < height_s; j++)
		{
			if(board[i][j] == '0')
				putSimbol('0', i, j);
		}
	}
}

/**
 * Draws the actor
 */
void draw_actor()
{
	//putSimbol(unsigned char c, unsigned char x, unsigned char y)
	putSimbol('X', actor_x, actor_y);
}

/**
 * Draws the destination
 */
void draw_dest()
{
	putSimbolColor('a', dest_x, dest_y, 0x04);
}

/**
 * Tests for actor/destination colision
 */
char colision()
{
	return ((actor_x == dest_x && actor_y == dest_y)) ? 1 : 0;
}

char colision_obstacle()
{
	return ((board[actor_x][actor_y] == '0')) ? 1 : 0;
}

/**
 * Main game loop
 */
void maze()
{
	int i, j;
	char x, y;

	cls();

	puts("Welcome to \"the MAZE\"!\nUse the arrows to control your character(x) to get to the destination(a).");
	puts("\nUse 'q' to quit. Press any key to begin...");
	wait_key();

	cls();

	// Generate all data for the game

	// Generate actor pos
	actor_x = rand() % width_s;
	actor_y = rand() % height_s;

	// Generate cestination pos
	dest_x = rand() % width_s;
	dest_y = rand() % height_s;

	// Clear board
	for(i = 0; i < width_s; i++)
	{
		for(j = 0; j < height_s; j++)
		{
			board[i][j] = 0;
		}
	}

	// Generate obstacles
	for(i = 0; i < 150; i++)
	{
		x = rand() % width_s;
		y = rand() % height_s;

		if(x != actor_x && x != dest_x &&
			y != actor_y && y != dest_y)
		{
			board[x][y] = '0';
		}
	}

	unsigned char win = 0;
	unsigned char option = 0;

	while(option != 'q' && win == 0)
	{
		// Clear screen
		cls();

		// Draw actors and board
		draw_board();
		draw_actor();
		draw_dest();

		option = get_char();

		if(option == UP && actor_y > 0)
		{
			actor_y--;

			if(colision_obstacle()) 
				actor_y++;
		}
		else if(option == DOWN && actor_y < height_s - 1)
		{
			actor_y++;

			if(colision_obstacle())
				actor_y--;
		}
		else if(option == LEFT && actor_x > 0)
		{
			actor_x--;

			if(colision_obstacle())
				actor_x++;
		}
		else if(option == RIGHT && actor_x < width_s - 1)
		{
			actor_x++;

			if(colision_obstacle())
				actor_x--;
		}

		// Test colision
		if(colision())
		{
			win = 1;
		}
	}

	// Else we finished qxit game
	cls();

	puts("Game finished!\n");
}
