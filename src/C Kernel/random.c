/**
 * A implementation of the Mersene Twister for
 * generating random numbers
 */

#define length 624

const unsigned int bitMask_32 = 0xffffffff;
const unsigned int bitPow_31 = 1 << 31;
unsigned int mt[length];
unsigned int idx = 0;

void seed(unsigned int seed)
{
	mt[0] = seed;
	int i;
	
	for(i = 1; i < length; i++) 
	{
		mt[i] = (1812433253 * (mt[i-1] ^ (mt[i-1] >> 30)) + i) & bitMask_32;
	}
}

void gen()
{
	int i;
	unsigned int y;

	for(i = 0; i < length; i++)
	{
		y = (mt[i] & bitPow_31) + (mt[(i + 1) % length] & (bitPow_31 - 1));
		
		mt[i] = mt[(i + 397) % length] ^ (y >> 1);
		
		if(y % 2)
		{
			mt[i] ^= 2567483615;
		}
	}
}

unsigned int rand()
{
	if(idx == 0) 
	{
		gen();
	}
	
	unsigned int y = mt[idx];
	
	y ^= y >> 11;
	y ^= (y << 7) & 2636928640;
	y ^= (y <<15) & 4022730752;
	y ^= y >> 18;
	idx = (idx + 1) % length;
	
	return y;
}
