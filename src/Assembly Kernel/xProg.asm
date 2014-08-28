
 use16


   mov ax, 3000h  ; set up segments (for the kernel address...)
		  ; where the bootloader throws us

   mov ds, ax  ; data segment
   mov es, ax  ; extra segment
   mov fs, ax  ; f segment
   mov gs, ax  ; g segment

   cli
   mov ss, ax	      ; stack sgment at origin
   mov sp, 0x0FFFF    ; stack pointer at origin + 64k
   sti


 main:

   ; if we want we can jump back to the kernel any time :)
   ; but no...
   mov AH, 0Bh
   mov BH, 00h
   mov BL, 001b
   int 0x10


   mov si, msg1
   call print_string

   mov ax, 0
   int 16h     ; wait for key

   ; exit video mode...
   mov AH, 0Bh
   mov BH, 00h
   mov BL, 000b
   int 0x10

   ; jump to kernel
   jmp 0:0x7e00

 print_string:
  _print_string:

   lodsb

   or AL, AL

   jz _print_done


   mov AH, 0x0E
   int 0x10
 
   jmp _print_string
 
 _print_done:
   ret


  end equ 0x0D, 0x0A
  ; data seg
  msg1 db 'Hello from a program that is in user space!', end, end
  msg2 db 'From this point if we do not overwrite the kernel we can', end
  msg3 db 'jump back to it(address 0x7E00:0x0) any time.', end, end
  msg4 db 'This is just a demo to test the kernel''s capability to load', end
  msg5 db 'a file found on the disk. From this point we will work on the', end
  msg6 db 'xProto.bin program that should be the ''real'' protected mode', end
  msg7 db 'kernel that will load multiple tasks, set up the PIT, etc...', end
  msg8 db 'The new kernel will be written mostly in C.', end
  msg9 db 'Press any key to finish...', end





