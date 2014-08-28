#include <system.h>

#define DEBUG_WORKER 0

struct worker
{
	// Worker ID
	int WID;
	// Worker name
	char name[256];	
	// Saves current status to know where to return to
	struct regs status;
	// next worker
	struct worker *next;
};

#define MAX_WORKERS 50
// We wan have a max of MAX_WORKERS workers. We just use these in the linked list.
struct worker workers[MAX_WORKERS];

// Worker queue
struct worker *wqueue;

// Current worker
struct worker *currentWorker;

// Curent index in workers
int currentIndex;

int firstRun;

void worker_scheduler(struct regs *r)
{
	puts("\nSome off work!");	

	if(DEBUG_WORKER)
	{
		// Print register contents:
		puts("\n Register contents: ");
		
		// Segment
		puts("Segment:\n");
		puts("GS: "); print_number_u(r->gs); puts("\n");
		puts("FS: "); print_number_u(r->fs); puts("\n");
		puts("ES: "); print_number_u(r->es); puts("\n");
		puts("DS: "); print_number_u(r->ds); puts("\n");
		puts("\n");
		
		// General
		puts("General:\n");
		puts("EDI: "); print_number_u(r->edi); puts("\n");
		puts("ESI: "); print_number_u(r->esi); puts("\n");
		puts("EBP: "); print_number_u(r->ebp); puts("\n");
		puts("ESP: "); print_number_u(r->esp); puts("\n");
		puts("EBX: "); print_number_u(r->ebx); puts("\n");
		puts("EDX: "); print_number_u(r->edx); puts("\n");
		puts("ECX: "); print_number_u(r->ecx); puts("\n");
		puts("EAX: "); print_number_u(r->eax); puts("\n");
		puts("\n");
		
		// Special
		puts("Special:\n");
		// Code
		puts("EIP: "); print_number_u(r->eip); puts("\n");
		puts("CS: "); print_number_u(r->cs); puts("\n");
		puts("EFLAGS: "); print_number_u(r->eflags); puts("\n");	
		// Stack
		puts("USER ESP: "); print_number_u(r->useresp); puts("\n");
		puts("SS: "); print_number_u(r->ss); puts("\n");
		
		// Int no
		puts("Interrupt number: "); print_number(r->int_no); puts("\n");
		puts("Processor halted.");
		// Halt processor
		for(;;);
	}
	
	/*
	// Copy the status to the current worker
	memcpy(&(currentWorker->status), r, sizeof(struct regs));
	
	// Go to the next worker in queue, else if it's null go to the start
	if(currentWorker->next)
	{
		currentWorker = currentWorker->next;
	}
	else 
	{
		currentWorker = wqueue;
	}
		
	// Now modify the (r) registers so we know where to start
	memcpy(r, &(currentWorker->status), sizeof(struct regs));
	*/
}

int assignWID()
{
	// Atm the current index is the WID
	return currentIndex;
}

/**
 * Initializes a worker. It sets it's name and entry point.
 */
void worker_init(char *name, void (*entry)()) 
{
	// Long long TODO: here set a GDT for each worker

	// Should add checks here
	//memcpy(workers[currentIndex].name, name, strlen(name));
	workers[currentIndex].WID = assignWID();
	workers[currentIndex].next = 0;
	
	// Setup the registers of the worker so we know where to go
	
	unsigned int dataDescriptor = 0x10;
	unsigned int codeDescriptor = 0x08;
	
	workers[currentIndex].status.ds = dataDescriptor;
	// Stack segment
	workers[currentIndex].status.ss = dataDescriptor;
	
	// Set stack to newly alocated memory
	workers[currentIndex].status.useresp = alloc();

	// EIP is set to the entry
	workers[currentIndex].status.eip = entry;
	
	// CS is set to code descriptor
	workers[currentIndex].status.cs = codeDescriptor;
	
	// Add the new process to the end of the queue
	struct worker *last = wqueue;
	if(!last)
	{
		wqueue = &(workers[currentIndex]);
	}
	else
	{
		// Goto last entry
		while(last->next)
		{
			last = last->next;
		}
		last->next = &(workers[currentIndex]);
	}
	
	currentWorker = wqueue;
	
	// Increment current index
	currentIndex++;
}

void workers_init()
{
	firstRun = 1;

	// Init globals (don't forget C initializes them to 0)
	currentIndex = 0;
	
	// Clear the workers
	memset(workers, 0, sizeof(struct worker) * MAX_WORKERS);

	// We override the timer's handler
	irq_install_handler(0, worker_scheduler);
}
