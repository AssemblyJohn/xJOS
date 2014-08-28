use32
ORG 0x30000	 ; add to offsets

start:
   xor ax, ax	; make it zero
   mov ds, ax	; DS=0
   mov ss, ax	; stack starts at 0
   mov sp, 0x9c00   ; 200h past code start

   mov al, 'h'
   mov ah, 0x0E
   int 0x10
   mov al, 'h'
   mov ah, 0x0E
   int 0x10
   mov al, 'h'
   mov ah, 0x0E
   int 0x10
 
   cli	    ; no interrupt
 
   lgdt [gdtinfo]   ; load gdt register
 
   mov	eax, cr0   ; switch to pmode by
   or al,1	   ; set pmode bit
   mov	cr0, eax
 
   mov	bx, 0x10   ; select descriptor 1
   mov	ds, bx	 ; 8h = 1000b

   sti
 
   mov bx, 0x0f01   ; attrib/char of smiley
   mov eax, 0x0b8000 ; note 32 bit offset
   mov word [ds:eax], bx
 
   jmp 0x08:prot      ; loop forever
   prot:

align 4
gdtinfo:
   dw gdt_end - gdt - 1   ;last byte in table
   dd gdt	  ;start of table
align 4
gdt	   dd 0,0  ; entry 0 is always unused
flatcode    db 0xff, 0xff, 0, 0, 0, 10011010b, 11001111b, 0
flatdesc    db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
gdt_end:

