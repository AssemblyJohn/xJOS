#include <system.h>

/*
 * =================================================
 * Memory functions.
 * Leaves the first 2 mb for the kernel and allocated
 * memory is after those 2mb of memory.
 * =================================================
 */

// TODO:
// Should use the INT 15 interupt in bios and detect memory and
// after that we should know here how much memory we have.

// Some primitive functions for allocing and freeing memory

// MAP(atm): Start: 0x00100000 End: 0x00EFFFFF Size: 0x00E00000
// We start at 1MB and let for the kernel until 2MB (0x00200000)
// From 0x00200000 to 0x00E00000 (12 MB for use)

// Where the memory starts
#define ADDR_START	 		0x00200000
// Where it ends
#define ADDR_END	   		0x00E00000
// It's size
#define ADDR_SIZE  			0x00C00000
// How much we allocate for an alloc call (4096 bytes or 4kb)
#define ADDR_CHUNK			0x1000 
// How many entries we have of 4kb (3072(0xC00) entries)
#define ADDR_ENTRY_COUNT	((ADDR_SIZE) / (ADDR_CHUNK))

struct m_entry
{
	unsigned int address;
	unsigned char taken;
};

struct mem_map
{
	// Table of memory entries
	struct m_entry mem_entry[ADDR_ENTRY_COUNT];
};

struct mem_map memory_map;

struct m_entry *hash_map_entry[ADDR_ENTRY_COUNT];

int to_hash(unsigned int address)
{
	return (address % ADDR_ENTRY_COUNT);
}

/**
 * Adds a entry to the map so we can find it 
 * very fast at free.
 */
void add_hash(struct m_entry *entry)
{
	// Generate hash code
	int hash_code = to_hash(entry->address);

	// Adds the entry to the map
	hash_map_entry[hash_code] = entry;
}

/**
 * Removes an entry from the map by
 * looking for the structure.
 */
void remove_hash(unsigned int address)
{
	// Generates hash
	int hash_code = to_hash(address);

	// Marks entry as not taken
	hash_map_entry[hash_code]->taken = 0;
	// Clears entry from map
	hash_map_entry[hash_code] = 0;
}

/**
 * Allocates a 4kb area of memory for
 * the calling program and returns it's
 * address or 0 in case of error.
 */
void* alloc()
{
	int i;
	int found = 0;

	unsigned int address = 0;
	void *pointer;

	// Temporary memory entry
	struct m_entry *temp_entry;

	// Iterates through the map looking for a chunk not taken.
	for(i = 0; (i < ADDR_ENTRY_COUNT) && (found == 0); i++)
	{
		temp_entry = &(memory_map.mem_entry[i]);
		if(temp_entry->taken == 0)
		{
			// We have found a chunk
			found = 1;

			// Mark the entry as taken
			temp_entry->taken = 1;
			// Set the address to a valid number
			address = temp_entry->address;

			// After we find the empty entry add it to the hash map
			// so we can free it by looking in the map rather than 
			// looking through all the list.
			add_hash(temp_entry);
		}
	}

	// If one is found it's address is returned, else 0 is returned.
	pointer = (void *)address;

	return pointer;
}

/**
 * Frees a previously allocated area of
 * memory.
 */
void free(unsigned int address)
{
	remove_hash(address);
}

void memory_init()
{
	int i;
	unsigned int start_addr = ADDR_START;
	unsigned int chunk_size = ADDR_CHUNK;

	// Clear the memory map
	memset(&memory_map, 0, sizeof(struct mem_map));
	// Clear the hash map
	memset(&hash_map_entry, 0, (sizeof(struct m_entry*) * ADDR_ENTRY_COUNT));

	// Set all to free
	for(i = 0; i < ADDR_ENTRY_COUNT; i++)
	{
		// Initalize the base address
		memory_map.mem_entry[i].address = (start_addr) + (chunk_size * i);
		// Mark it as not taken
		memory_map.mem_entry[i].taken = 0;
	}
}
