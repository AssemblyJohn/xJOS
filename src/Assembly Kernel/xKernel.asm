; Created by Lazu Ioan-Bogdan

use16 ; we will use 16 bits here and 32 on the next stuff

diskette_buffer equ 0x61FF

   ; =================
   ; MACROS
   MACRO NEWLINE
   {
      mov si, k_newline
      call print_string
   }
   MACRO PRINT string
   {
      mov si, string
      call print_string
   }
   MACRO CONSTRUCTION
   {
      mov si, msg_not_avail
      call print_string
   }

   MACRO DEBUG
   {
      pusha
      mov si, msg_debug
      call print_string
      popa
   }

   ; very usefull macro for comparing
   ; command and jumping to it's label
   MACRO COMMAND string, label
   {
      mov si, keyboard_buffer
      mov di, string
      call strcmp
      jc label
   }
   ; END MACROS
   ; =================


org 0x7e00
   ; crude irony... my bug was that it was 2000 instead of 2000h
   ;mov ax, 0x7e0  ; was 2000h now is 0x7e0
		  ; set up segments (for the kernel address...)
		  ; where the bootloader throws us
   xor ax, ax

   mov ds, ax  ; data segment
   mov es, ax  ; extra segment
   mov fs, ax  ; f segment
   mov gs, ax  ; g segment

   cli
   mov ss, ax	      ; stack sgment at origin
   mov sp, 0x0FFFF    ; stack pointer at origin + 64k
   sti

   ;===========================
   ; From now on we can use normal displacement
   ; ignoring all the segment stuff
   ;===========================
   cmp [g_inited], 0
   jne kernel_init

 kernel_not_init:
   ; move the boot device for file utils
   mov [bootDevice], dl
   NEWLINE
   mov si, msg_welcome
   call print_string	; print the greeing
   mov [g_inited], 1
   jmp mainloop

 kernel_init:
   NEWLINE
   mov si, msg_welcome_back
   call print_string


 mainloop:

   mov si, cmd_prompt	; print the '>>'
   call print_string
 
   mov di, keyboard_buffer	 ; move keyboard_buffer to DI and get string
   call get_string	; call get string
 
   mov si, keyboard_buffer	 ; move keyboard_buffer in SI
   cmp byte [si], 0	; null line?
   je mainloop		; yes, ignore it

   ; ----------
   ; Actual start of command proccesing
   ; ----------

   ; 'hi'
   COMMAND cmd_hi, .cmd_hi
   ; 'help'
   COMMAND cmd_help, .cmd_help
   ; 'xhelp'
   COMMAND cmd_xhelp, .cmd_xhelp
   ; 'cls
   COMMAND cmd_cls, _cmd_cls
   ; 'diagnose'
   COMMAND cmd_diagnose, .cmd_diagnose
   ; 'ticks'
   COMMAND cmd_ticks, .cmd_ticks
   ; 'dump'
   COMMAND cmd_dump, .cmd_dump
   ; 'a20'
   COMMAND cmd_a20, _cmd_atwenty
   ; 'time'
   COMMAND cmd_time, _cmd_time
   ; 'disktest'
   COMMAND cmd_ls, _cmd_ls
   ; 'restart'
   COMMAND cmd_restart, _cmd_reboot
   ; 'exec'
   COMMAND cmd_exec, _cmd_exec
   ; 'xprot'
   COMMAND cmd_xprot, _cmd_xprot

   ; ---------
   ; End of command processing
   ; ---------

   ; else the command was bad
   NEWLINE
   mov si, msg_badcommand
   call print_string 
   jmp mainloop

; ========================
; COMMAND PROCCESING
; ========================
 .cmd_hi:
   NEWLINE
   mov si, msg_helloworld
   call print_string
 
   jmp mainloop

 .cmd_help:
   NEWLINE
   mov si, msg_for_help
   call print_string

   jmp mainloop

 .cmd_xhelp:
   NEWLINE
   mov si, msg_help_ext
   call print_string

   jmp mainloop

 .cmd_ticks:
   NEWLINE

   xor AX, AX  ; null out AX
   int 0x1A    ; returns ticks since midnight in the CX:DX pair

   mov AX, CX
   call print_ax

   xor AX, AX  ; same here as above
   int 0x1A

   mov AX, DX
   call print_ax

   NEWLINE

   jmp mainloop

 .cmd_diagnose:
    xor ax, ax

    ; bios int for request low memory size
    int 0x12
    push ax

    ; if carry is set we have errror
    jc .cmd_diagnose_error
    test ax, ax
    ; if ax is 0 we have error
    jz .cmd_diagnose_error

    ; else we're cool and we can print the avail memory
    NEWLINE

    PRINT msg_memory_low_ok

    pop ax
    call print_ax

    NEWLINE

    ; now get other memory(high area)

    jmp mainloop

 .cmd_diagnose_error:
    NEWLINE
    PRINT msg_memory_error
    NEWLINE

    jmp mainloop

 .cmd_dump:
   ; dumps all general registers
   push bp
   push sp
   push ss
   push es
   push ds
   push di
   push si
   push dx
   push cx
   push bx
   push ax
   mov ax, cs
   push ax  ; push cs

   call _labelIP ; trick to get IP
  _labelIP:

   ; start print IP, CS
   NEWLINE
   PRINT reg_ip
   pop ax
   call print_ax

   NEWLINE
   PRINT reg_cs
   pop ax
   call print_ax
   ; end print IP, CS

   NEWLINE
   PRINT reg_ax
   pop ax
   call print_ax
   NEWLINE

   PRINT reg_bx
   pop ax
   call print_ax
   NEWLINE

   PRINT reg_cx
   pop ax
   call print_ax
   NEWLINE

   PRINT reg_dx
   pop ax
   call print_ax
   NEWLINE

   PRINT reg_si
   pop ax
   call print_ax
   NEWLINE

   PRINT reg_di
   pop ax
   call print_ax
   NEWLINE

   PRINT reg_ds
   pop ax
   call print_ax
   NEWLINE

   PRINT reg_es
   pop ax
   call print_ax
   NEWLINE

   PRINT reg_ss
   pop ax
   call print_ax
   NEWLINE

   PRINT reg_sp
   pop ax
   call print_ax
   NEWLINE

   PRINT reg_bp
   pop ax
   call print_ax
   NEWLINE

   jmp mainloop

 _cmd_cls:
   xor ax, ax
   mov ah, 0x0F ; get video mode
   int 10h	; returned in AL

   xor ah, ah	; 0x0 for set video mode
   int 10h	; we already have value in AL

   jmp mainloop

 ; Checks the a20 line. The a20 line is 
 ; the pin that allows us to access more than 1MB of memory.
 ; It is disabled by default to enable backwards compatibility
 ; with 8086 programs (ancient relics of the past that nowadays do not exist)
 ; that used the memory wraparound. The memory
 ; wraparound means that if i try to acces the byte just above
 ; 1MB it will actualy access the first byte in memory. If i try
 ; to access the address at 1.5MB then with the a20 line disabled
 ; i will access the byte at location 0.5MB. (it wraps around 0 or is
 ; calculated MEM_ADDRESS % 1MB).
 ;
 ; Had a bug here, i couldn't load the protected mode kernel here
 ; since OracleVM did not enabled the a20 line by default
 _cmd_atwenty:
   pushf
   push ds
   push es
   push di
   push si
 
   cli
 
   xor ax, ax ; ax = 0
   mov es, ax
 
   not ax ; ax = 0xFFFF
   mov ds, ax
 
   mov di, 0x0500
   mov si, 0x0510
 
   mov al, byte [es:di]
   push ax
 
   mov al, byte [ds:si]
   push ax
 
   mov byte [es:di], 0x00
   mov byte [ds:si], 0xFF
 
   cmp byte [es:di], 0xFF
 
   pop ax
   mov byte [ds:si], al
 
   pop ax
   mov byte [es:di], al
 
   mov ax, 0
   je cmd_atwenty_exit
 
   mov ax, 1
 
 cmd_atwenty_exit:
   pop si
   pop di
   pop es
   pop ds
   popf

   or ax, ax
   jz atwenty_not

   NEWLINE
   mov si, msg_a20_yes
   call print_string

   jmp mainloop

 atwenty_not:
   NEWLINE
   mov si, msg_a20_not
   call print_string

   ; enable a20 line if it is not enabled
   mov ax, 0x2401
   int 0x15

   jmp mainloop


 _cmd_time:
    ; here we read the time from CMOS
    ; problem with bochs, time ticks a lot faster

    NEWLINE
    mov cx, 3
    mov dx, 4

  cmd_time_loop:
    push cx
    push dx

    cli 	      ; disable interupts
    mov al, dl	      ; we read at port X(0 - 4 for time)
    out 0x70, al      ; we specify in out at which port we read
    in al,0x71	      ; we get in ax the value from the port 0x71
    sti 	      ; enable interupts again

    xor ah, ah	      ; null ah
    call print_al     ; print al

    pop dx
    sub dx, 0x02
    pop cx

    cmp cx, 1	       ; we print ':' only 2 times

    jz cmd_time_continue
    PRINT msg_time_sep

  cmd_time_continue:
    loop cmd_time_loop

    NEWLINE
    jmp mainloop


 _cmd_ls:
    NEWLINE
    NEWLINE
    call file_read_root

    jmp mainloop

 _cmd_exec:
   call file_get_search_filename
   NEWLINE

   mov [readAtEX], 3000h
   call file_load_file_with_name

   cmp [file_read_succes], 0
   jne _cmd_exec_succes
   jmp mainloop

  _cmd_exec_succes:

   jmp 3000h:0

 _cmd_reboot:
   NEWLINE
   PRINT msg_restart
   NEWLINE

   mov ax, 0
   int 16h     ; wait for key
   mov ax, 0
   int 19h     ; restart


 ; ================
 ; SUBROUTINES FOR KERNEL USE
 ; ================

 ; ==================
 ; get string function

 ; waits for key press and acts accordingly
 ; DI must be loaded with the address of the keyboard_buffer for stosb
 ; ==================
 get_string:
   xor CL, CL	     ; sets CL to 0 (faster than MOV CL, 0)
		     ; CL = lower part of CX (conventional counter reg)
 .get_string_loop:
   mov AH, 0		  ; when AH is 0, interupt 0x16 is for
   int 0x16		  ; for keyboard keypress (stores press in AL)
 
   cmp AL, [k_backspace]  ; backspace pressed (note the value from
			  ; k_backspace not it's address (without []'s))

			  ; recap (je = jump if equal, ZF = 1)
   je .backspace	  ; handle it
 
   cmp AL, [k_enter]	  ; enter pressed?
   je .get_string_done	  ; yes, we're done
 
   cmp CL, [kyeboard_buffer_len]	     ; 32 chars inputed
   je .get_string_loop	  ; yes, only let in backspace and enter

   ; if we passed all the jumps then we are good to print the pressed key
   mov ah, 0x0E 	  ; telnet print
   int 0x10		  ; print out character
 
   stosb		  ; put character in keyboard_buffer
   inc CL		  ; increment CL for the test
			  ; with numberr of characters inputed
   jmp .get_string_loop   ; jump to the begining of the loop again
 
 .backspace:
   cmp CL, 0		  ; if begining of the string
   je .get_string_loop	  ; just ignore the key
 
   dec DI
   mov byte [DI], 0	  ; delete character (put zero in it)
   dec DL		  ; decrement counter as well
 
   mov ah, 0x0E 	  ; telnet print
   mov al, [k_backspace]  ; with backspace character
   int 10h		  ; int 10h for telent
 
   mov al, ' '		  ; blank character
   int 10h		  ; blank character out
 
   mov al, [k_backspace]  ; backspace
   int 10h		  ; backspace again
 
   jmp .get_string_loop   ; go to the main loop
 
 .get_string_done:
   mov al, 0		  ; null terminator
   stosb		  ; store it in the keyboard_buffer

   mov ah, 0x0E 	  ; telnet print
   mov al, [k_enter]	  ; enter key
   int 0x10		  ; print enter
   mov al, [k_newline]	  ; newline char
   int 0x10		  ; newline print
 
   ret			  ; return from function call

; ==========================
; DATA PART HERE
; ==========================

   include 'stringData.inc'

   ; keyboard buffer 32 characters
   keyboard_buffer RB 32
   kyeboard_buffer_len DB 32

   msg_debug db 'DEBUG',0

   ; temporary variables for diferent uses
   g_wtemporary RW 1
   g_dtemporary RD 1

   g_btemp1	RB 1
   g_btemp2	RB 1
   g_btemp3	RB 1

   ; if the kernel was initialized
   g_inited	DB 0

   ; constants

   ; key constants
   k_backspace DB 0x08
   k_enter     DB 0x0D

   ; print constants
   k_newline   DB 0x0D, 0x0A, 0


   ; include other auxiliary stuff
   include 'xString.asm'
   include 'xFileUtils.asm'


; ==========================
; START XPROT
; ==========================

 ; last command here since it's the most important
 _cmd_xprot:
   NEWLINE
   PRINT file_xprot_info
   NEWLINE
   ; we copy the filename (presuming we have it)
   cli
   mov si, file_xprot
   mov di, filenameBuffer
   mov cx, 11
   rep movsb

   ; We load the file here at 0x1000(real address 0x10000)
   mov [readAtEX], 0x1000
   mov [file_read_succes], 0
   call file_load_file_with_name

   cmp [file_read_succes], 0
   jne _cmd_xprot_success
   ; failure we just jump back to main
   PRINT file_xprot_failure
   jmp mainloop

   ; if we suceed we go on
 _cmd_xprot_success:
   PRINT file_xprot_success

   ; RB's inter list
   ; INT 10 - VESA SuperVGA BIOS - SET SuperVGA VIDEO MODE
   ;      AX = 4F02h
   ;      BX = new video mode (see #04082,#00083,#00084)
   ; 118h =  1024x768x16M
   ;mov ax, 4F02h
   ;mov bx, 118h
   ;int 10h

   cli	     ; no interrupts while setting the gdt
 
   lgdt [gdtdata]

   ; switch on the pmode bit
   mov	eax, cr0
   or al,1
   mov	cr0, eax

   ; flush prefetch queue by jumping with selector 1
   jmp 0x08:PMODE

 use32
 PMODE:
   mov ax, 0x10

   ; load registers with descriptor 2
   mov ss, ax
   mov ds, ax
   mov es, ax
   mov gs, ax
   mov fs, ax

   ; clear direction flag
   cld
   ; mov in esi the address where we will load the kernel from
   ; (we loaded it a little earlier)
   mov esi, 0x10000
   ; mov in edi the destination where we will move it
   mov edi, 0x100000
   ; atm move just 65535 bytes, in future we can change to load
   ; bigger kernels
   mov ecx, 0xFFFF
   ; move
   rep movsb

   ; after we are finished loading we jump to that kernel!!!
   ; YEEEEY! worked from the first time!
   jmp 0x08:0x100000


;========================
; start gdt
;========================
; global descriptor table (see notebook for details)

gdtdata:
   dw gdtdata_end - gdt - 1
   dd gdt

gdt	    db	0,    0,   0, 0, 0,	0,	    0,	  0
flatcode    db 0xff, 0xff, 0, 0, 0, 10011010b, 11001111b, 0
flatdata    db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
gdtdata_end:
;========================
; end gdt
;========================
