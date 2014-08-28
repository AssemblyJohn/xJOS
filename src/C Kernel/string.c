#include <system.h>
#include <math.h>

/*
 * ======================================
 * Some string/number utils
 * ======================================
 */

/**
 * String length.
 */
int strlen(const char *str)
{
    int retval;
    for(retval = 0; *str != '\0'; str++) retval++;
    return retval;
}

/**
 * Return 1 if they are equal, or 0 otherwise
 */
char strcompare(const char *str1, const char *str2)
{
	int len1 = strlen(str1);
	int len2 = strlen(str2);

	int i;

	if(len1 != len2)
	{
		return 0;
	}
	else
	{
		for(i = 0; i < len1; i++)
		{
			if(str1[i] != str2[i])
			{
				return 0;
			}
		}

		return 1;
	}
}

/**
 * Inverts a string
 */
void strrev(char *str, int len)
{
	int i;
	int a, b;
	int to;
	char temp;
	
	a = 0;
	b = len;
	to = b / 2;
	// Since len is not the last element
	b--;
	
	for(i = 0; i < to; i++)
	{
		temp = str[a];
		str[a] = str[b];
		str[b] = temp;
		
		a++;
		b--;
	}
}
 
// TODO: i would be a lot happier with these written
// in assembly since we could use a hardware loop (like rep movsb)
// Change it to assembly

void *memcpy(void *dest, const void *src, int count)
{
    const char *sp = (const char *)src;
    char *dp = (char *)dest;
    for(; count != 0; count--) *dp++ = *sp++;
    return dest;
}

void *memset(void *dest, char val, int count)
{
    char *temp = (char *)dest;
    for( ; count != 0; count--) *temp++ = val;
    return dest;
}

unsigned short *memsetw(unsigned short *dest, unsigned short val, int count)
{
    unsigned short *temp = (unsigned short *)dest;
    for( ; count != 0; count--) *temp++ = val;
    return dest;
}

char decimal_table[] = "0123456789";
char hex_table[] = "0123456789ABCDEF";

// 4 bilions have 10 numbers + null teminator + '-' if it's negative
char temp[12];
char final[12];

// Hex table
char nr_hex[3];

/**
 * Clears the table of junk
 */ 
void clear_table()
{
	int i;
	for(i = 0; i < 12; i++)
	{
		temp[i] = final[i] = '\0';
	}
}

/**
 * Prints a signed integer number 
 */
void print_number(int number)
{
	clear_table();

	int i, j;
	i = 0;
	
	char neg = (number < 0) ? 1 : 0;
	char nrlen;
	
	while(number != 0)
	{
		temp[i++] = decimal_table[abs(number % 10)];
	
		number /= 10;
	}
	
	nrlen = i;
	
	strrev(temp, nrlen);
	
	if(neg)
	{
		final[0] = '-';
	}
	
	for(i = ((neg) ? 1 : 0), j = 0; j < nrlen; i++, j++)
	{
		final[i] = temp[j];
	}
	
	puts(final);
}

/**
 * Prints a unsigned integer number
 */
void print_number_u(unsigned int number)
{
	clear_table();

	int i, j;
	i = 0;
	
	while(number != 0)
	{
		temp[i++] = decimal_table[number % 10];
	
		number /= 10;
	}
	
	strrev(temp, i);
	
	for(; i >= 0; i--)
	{
		final[i] = temp[i];
	}
	
	puts(final);
}

char *get_number_u(unsigned int number)
{
	clear_table();

	if(number == 0)
	{
		final[0] = '0';
		return final;
	}

	int i, j;
	i = 0;
	
	while(number != 0)
	{
		temp[i++] = decimal_table[number % 10];
	
		number /= 10;
	}
	
	strrev(temp, i);
	
	for(; i >= 0; i--)
	{
		final[i] = temp[i];
	}

	return final;
}

/**
 * Prints a byte in hex
 */
void print_hex_byte(unsigned char byte)
{
	unsigned char upper = byte >> 4;
	unsigned char lower = byte & 0x0F;
	
	nr_hex[0] = hex_table[upper];
	nr_hex[1] = hex_table[lower];
	nr_hex[2] = '\0';
	
	puts(nr_hex);
}

/**
 * Returns a pointer to a table that contains a null teminated string that
 * contains in hex the value of the byte. Used for drawing the byte at 
 * custom positions.
 */
char* get_hex_byte(unsigned char byte)
{
	unsigned char upper = byte >> 4;
	unsigned char lower = byte & 0x0F;
	
	nr_hex[0] = hex_table[upper];
	nr_hex[1] = hex_table[lower];
	nr_hex[2] = '\0';
	
	return nr_hex;
}
