#include <system.h>
#include <random.h>

/*
 * ================================================='
 * Timer utilitaries
 * =================================================
 */

char process_paused = 0;

// How many tiks the system runned for
volatile int timer_ticks = 0;

/**
 * Set timer phase at hz.
 */
void timer_phase(int hz)
{
    int divisor = 1193180 / hz;       /* Calculate our divisor */
    out(0x43, 0x36);             /* Set our command byte 0x36 */
    out(0x40, divisor & 0xFF);   /* Set low byte of divisor */
    out(0x40, divisor >> 8);     /* Set high byte of divisor */
}

char x = 70;
char y = 0;
char empty = 0;

/**
 * Handles the timer.
 */
void timer_handler(struct regs *r)
{
	if(process_paused)
		return;

	char c;

	char cmp1 = 0;
	char cmp2 = 0;

    timer_ticks++;
	
	// Called every second
    if (timer_ticks % 60 == 0)
    {
        //puts("One second has passed\n");
    }

	// Every 300 ms
	if(timer_ticks % 20 == 0)
	{
		if(empty == 0)
		{
			out(0x70, 0);
		
			seed(in(0x71));

	    	if(rand() % 2 == 0) 
			{
				c = '0';
			}
			else
			{
				c = '1';
			}
		} 
		else
		{
			c = ' ';
		}

		putSimbol(c, x, y);

		// update x and y
		// TODO:
		y++;

		if(y >= 5)
		{
			x++;
			y = 0;

			cmp1 = 1;
		}

		if(x >= 80)
		{
			x = 70;

			cmp2 = 1;
		}

		// Complete run
		if(cmp1 && cmp2)
		{
			empty = !empty;
		}
	}
}

/**
 * Wait method.
 */
void timer_wait(int ticks)
{
    int eticks;

    eticks = timer_ticks + ticks;
    while(timer_ticks < eticks);
}

/**
 * Set up the clock by installing it.
 */
void timer_install()
{
    /* Installs 'timer_handler' to IRQ0 */
    irq_install_handler(0, timer_handler);
}
