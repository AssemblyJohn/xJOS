; Created by Lazu Ioan-Bogdan

  ; File utilitaries. Reads files, reads content into location in memory,
  ; migh even execute some code it it is loaded!
  ; TODO: usage for commands: LIST, LOAD, EXECUTE
  ; LIST - lists files on floppy
  ; LOAD - loads a file in memory and hex dump it
  ; EXECUTE - loads a file in memory and jumps to it
  ; TODO: reuse most of the bootloader

  ; ================
  ; Initializes searchFilename here
  ; ================
  file_get_search_filename:
     NEWLINE
     PRINT file_input_filename

     ; reset filename because of previous junk
     mov cx, 11
     mov ax, ' '
     mov di, filenameBuffer
     rep stosb
     ; end reset

     mov di, filenameBuffer
     call file_get_filename


     NEWLINE
     PRINT file_got_name
     PRINT filenameBuffer
     NEWLINE

     ret

 ; ================
 ; Reads a file based on the content of searchFilename
 ; searchFilename must be initialized before using this function
 
 ; Trashed all registers
 ; file_read_succes != 0 if we have success
 ; ================
 file_load_file_with_name:
   mov [file_read_succes], 0

   mov ax, 19
   call file_logical_to_hts  ; convert from logical to head/track/sector

   mov si, diskette_buffer  ; our buffer(14 * 512 = 7168
   mov bx, ds	   ; get data segment
   mov es, bx	   ; so ES points to the right location
   mov bx, si	   ; and now ES:BX is (current ES:diskette_buffer)

   mov ah, 2	   ; int for read sectors
   mov al, 14	   ; read 14 sectors

   pusha	   ; push all general registers, prepare to enter loop

 file_read_root_dir:
   popa 	   ; case regs are altered
   pusha	   ; in case regs are altered

   stc		   ; not set on error on some bioses
   int 13h

   jnc file_search_dir	; if carry not set we're succesfull
   call file_reset_diskette
   jnc file_read_root_dir

   jmp file_fatal_error    ; on double error just reboot

 file_search_dir:
   popa 	   ; get all our registers back

   mov di, diskette_buffer  ; now DI points to our buffer...

   mov cx, 224
   mov ax, 0
   
 file_next_root_entry:
   xchg cx, dx			 ; use dx as a cache
   
   mov si, filenameBuffer ; filename
   mov cx, 11			 ; filename is 11 ascii chars long
				 ; so we neet to loop 11 times to compare all bytes
   rep cmpsb			 ; rep cmpsb = hardware repeat compare string byte

   je file_found_file_to_load	 ; if they're all equal
				 ; (DI will be at offset 11)
   ; else we didn't found it
   add ax, 32			 ; 32 more bytes add for next file entry

   mov di, diskette_buffer	 ; move again since it is trashed by rep cmpsb
   add di, ax			 ; add it by new offset
				 ; (will be 0, 32, 64, 96, 128, etc)

   xchg dx, cx			 ; get old CX back from it's DX cache
   loop file_next_root_entry	      ; if CX is not 0 loop again

   ; else print not found message and reboot
   mov si, file_not_found
   call print_string
   jmp file_fatal_error

 file_found_file_to_load:	   ; we fount kernel

   mov ax, word [es:di+15]   ; from the docs(see notebook) we know the first
			     ; cluster from a file is from byte 26 to byte 28
			     ; from 28 to 32 we have file size in bytes

   mov word [cluster], ax    ; store first cluster position
			     ; at this moment we got the good cluster to load

   mov ax, 1		     ; FAT table starts at sector 1
   call file_logical_to_hts  ; for calculating sector in head/track/sector

   mov bx, diskette_buffer   ; now ES:BX point to buffer again

   mov ah, 2		     ; bios interrupt
   mov al, 9		     ; read ALL fat table(we know from docs it's
			     ; 9 sectors big)

   pusha		     ; prepare for read loop

 file_read_fat:
   popa
   pusha

   stc
   int 13h

   jnc file_read_fat_ok 	  ; if were ok proceed
   call file_reset_diskette	  ; else reset floppy
   jnc file_read_fat		  ; else again try read

   call file_fatal_error	     ; if we got double error reset

 file_read_fat_ok:	     ; now we have FAT in diskette_buffer
			     ; don't forget [cluster] also contains
			     ; the value we have to load
   popa 		     ; restore registers

   mov ax, [readAtEX]	     ; we load at where we say :)
   mov es, ax
   mov bx, 0

   mov ah, 2		     ; for int 13h read floppy
   mov al, 1		     ; we will always read only 1 sector
			     ; (we read 1 sector at the time because of
			     ; the fragmentation (see notebook))

   push ax		     ; so we don't trash it (we save ah 2 and al 1)
			     ; will be the same for all sector reads
				 
 file_load_file_sector:
   ; in this part we are going to read the kernel sector by sector
   mov ax, word [cluster]   ; don't forget the cluseter holds the first sector
			    ; from the file that we have to read.
			    ; don't forget it also points to the location
			    ; in the fat table. With that location
			    ; we will also be able to get the CONTENT of that
			    ; FAT entry and see if there is a next sector
			    ; that we have to load or if we reached EOC
			    ; (end of clusterchain)
			    ; see notebook for details
   add ax, 31		    ; don't forget data sectors start at 33 and we add
			    ; by 31 because the first fat MUST 2 or greater
			    ; formula(33  + n - 2 (since first 2 are reserved))
			    ; see notebook for details
   call file_logical_to_hts ; convert logical to real

   mov ax, [readAtEX]	    ; location where we will load
   mov es, ax
   mov bx, word [pointer]   ; we set the buffer past what we've already read
			    ; it will be incremented 512 by 512 after each
			    ; succesfull sector reading
   pop ax		    ; get the ax pushed a little earlier
   push ax		    ; push it again so we save AH and AL(AH for int 13h
			    ; and AL for 1(always read 1 sector))
   stc
   int 13h		    ; read it...

   ; if we're cool calculate next cluster and goto load_xkern_sector again
   jnc file_calc_next_cluster
   call file_reset_diskette	 ; else reset floppy
   jmp file_load_file_sector	; and after reset try again... until we suceed


 file_calc_next_cluster:
   mov ax, [cluster]	   ; don't forget at first call of this
			   ; we still have the original cluster here
			   ; don't forget the diskette_buffer contains
			   ; the fat tables too
   mov dx, 0
   mov bx, 3
   mul bx		   ; multiplies AX(accumulator) with BX(word) and result
			   ; is stored in DX:AX (we apply the above formula)
			   ; DX:AX = Q =(3 * n) where n is [cluster]
   mov bx, 2
   div bx		   ; DX:AX = Q / 2 (second part of above formula)
			   ; AX holds the value and DX holds the remainder
			   ; (for ASM instructions see docs)
			   ; depending on DX we have even/uneven entry and
			   ; we must act accordingly

   mov si, diskette_buffer	    ; get diskette buffer in SI
   add si, ax		   ; we have fat entry position
   mov ax, word [ds:si]    ; load in AX the actual entry to the first fat entry
				; (2 bytes, 16 bits, 1 word)
			   ; note that we still must mask some bits that
			   ; should not be there
   or dx, dx		   ; see odd/even (if DX = 0 even else odd)
   jz file_cluster_even

 file_cluster_odd:
   shr ax, 4		   ; shift right the first 4 bits since they
			   ; belong to some other entry
   jmp short file_cluster_next	; get over cluster even

 file_cluster_even:
   and ax, 0FFFh	   ; mask final 4 bits(bits are read right to left dont
			   ; forget that

 file_cluster_next:
   mov word [cluster], ax  ; move in [cluster] the content of [cluster]
			   ; (since for the first time it held only
			   ; the position of the first cluster)

   cmp ax, 0FF8h	   ; the 0FF8 is the end of file marker in fat12/16
			   ; and 0FFF is end of EOC(end of clusterchain)
   jae file_end 	       ; if it's the last cluster we're done YEY!
			   ; don't forget jae (above equal) since all
			   ; that is above 0FF8h is EOF/EOC

   ; else we update buffer pointer by 1 sector length and we jump again...
   add word [pointer], 512
   jmp file_load_file_sector

 file_end:
   mov ax, 2000h
   mov es, ax

   mov [file_read_succes], 1
   PRINT file_succes	  ; print the succes
   pop ax		  ; I forogt a pop somwhere...


   ret

 ; ================
 ; read root dir and prints all it's files

 ; trashes all registers
 ; JC set on error
 ; ================
 file_read_root:
  mov ax, 19
  call file_logical_to_hts

  mov si, diskette_buffer
  mov bx, ds
  mov es, bx
  mov bx, si

  mov ah, 2
  mov al, 14

  pusha

 file_root_read_root_dir:
   popa      ; case regs are altered
   pusha	   ; in case regs are altered

   stc		   ; not set on error on some bioses
   int 13h

   jnc file_root_search_dir  ; if carry not set we're succesfull
   call file_reset_diskette
   jnc file_root_read_root_dir

   jmp file_root_read_root_error	    ; on double error set jc and return

 file_root_search_dir:
   popa 	   ; get all our registers back

   mov di, diskette_buffer  ; now DI points to our buffer...

   mov cx, 224	   ; number of entries
   mov ax, 0

 file_root_next_root_entry:
   xchg cx, dx			 ; use dx as a cache

   mov si, di

   ; if it is 0 it poses no interest for us
   cmp byte [di], 0
   je file_root_read_root_skip
   ; if it is 0xE5 it means it is unused and we should not read it
   cmp byte [di], 0xE5
   je file_root_read_root_skip

   ; Print 11 chars of the si
  mov cx, 11
  file_root_filename_loop:

   push cx
   push ax

   mov al, byte [si]
   push si
   call print_char
   pop si
   inc si

   pop ax
   pop cx

   loop file_root_filename_loop

   pusha
   NEWLINE
   popa


  file_root_read_root_skip:
   ; else we didn't found it
   add ax, 32			 ; 32 more bytes add for next file entry

   mov di, diskette_buffer	 ; move again since it is trashed by rep cmpsb
   add di, ax			 ; add it by new offset
				 ; (will be 0, 32, 64, 96, 128, etc)

   xchg dx, cx			 ; get old CX back from it's DX cache
   loop file_root_next_root_entry	 ; if CX is not 0 loop again

   ; else print not found message and reboot
   jmp file_root_read_root_succes


 file_root_read_root_error:
  stc
  NEWLINE
  PRINT msg_disk_error

  ret

 file_root_read_root_succes:
  clc
  NEWLINE
  PRINT file_read_root_dirs_succes

  ret

 ; ================
 ; reset floppy function

 ; carry set on error
 ; no registers are trashed
 ; ================
 file_reset_diskette:
   push ax		       ; push ax, dx so we don't trash them
   push dx
   xor ax, ax		       ; Reset disk system (al = 0)
   mov dl, byte [bootDevice]   ; move saved boot device
   stc			       ; set it since some bioses have some bugs
			       ; and do not set it on error. so we set it
			       ; and expect the bios to clear it if it' sucesfull
   int 0x13		       ; int 13h (disk stuff)

   pop dx
   pop ax
   ret			       ; return


 ; =================
 ; locagical to head/track/sector

 ; calculates from a logical sector the
 ; registers for read disk interrupt
 ; DH = head number
 ; CH = track number
 ; CL = sector number

 ; DL = device
 ; =================
 file_logical_to_hts:
   push bx		       ; save bx, ax which we will sue
   push ax

   mov bx, ax		       ; Save logical sector

   mov dx, 0		       ; first we get the sector
   div word [SectorsTrack]     ; (logical / 18 gives us the sector)
   add dl, 01h		       ; add one since they start at 1 (if logical > 18)
			       ; (we only need the remainder)
   mov cl, dl		       ; get the value from DL (since 18 < 255 we can safely
			       ; say that we only need the lower part of DX)
			       ; CL = sector number for int 13H
			       ; sectors are 1 - 18 for each track
   mov ax, bx		       ; get again the logical sector cached in BX

   ; from AX we will get the track number (quotient)
   ; and from DX we will get the head number (remaining)
   ; if sector even head = 0, sector uneven head = 1
   ; (the calculation is a little ambiguous)
   mov dx, 0		       ; now calculate head/track
   div word [SectorsTrack]     ; (logical / 18)
   mov dx, 0
   div word [Heads]	       ; (logical / 2)
   mov dh, dl		       ; DH = head for int 13h
			       ; in DX we get the head
   mov ch, al		       ; CH = track for int 13h
			       ; in AX we get the track

   pop ax
   pop bx

   mov dl, byte [bootDevice]   ; set device given to us by bootloader

   ret
   
 file_fatal_error:
   NEWLINE
   mov si, file_utils_error
   call print_string
   NEWLINE
 
   ret


 ; ==================
 ; get string function same as kernel's
 ; ==================
 file_get_filename:
   xor CL, CL	     ; sets CL to 0 (faster than MOV CL, 0)
		     ; CL = lower part of CX (conventional counter reg)
 .file_get_string_loop:
   mov AH, 0		  ; when AH is 0, interupt 0x16 is for
   int 0x16		  ; for keyboard keypress (stores press in AL)
 
   cmp AL, [k_backspace]  ; backspace pressed (note the value from
			  ; k_backspace not it's address (without []'s))

			  ; recap (je = jump if equal, ZF = 1)
   je .file_backspace	       ; handle it
 
   cmp AL, [fi_k_enter]      ; enter pressed?
   je .file_get_string_done    ; yes, we're done
 
   cmp CL, [filenameLen]	     ; 11 chars inputed
   je .file_get_string_loop    ; yes, only let in backspace and enter

   ; if we passed all the jumps then we are good to print the pressed key
   mov ah, 0x0E 	  ; telnet print
   int 0x10		  ; print out character
 
   stosb		  ; put character in keyboard_buffer
   inc CL		  ; increment CL for the test
			  ; with numberr of characters inputed
   jmp .file_get_string_loop   ; jump to the begining of the loop again
 
 .file_backspace:
   cmp CL, 0		  ; if begining of the string
   je .file_get_string_loop    ; just ignore the key
 
   dec DI
   mov byte [DI], 0	  ; delete character (put zero in it)
   dec DL		  ; decrement counter as well
 
   mov ah, 0x0E 	  ; telnet print
   mov al, [fi_k_backspace]  ; with backspace character
   int 10h		  ; int 10h for telent
 
   mov al, ' '		  ; blank character
   int 10h		  ; blank character out
 
   mov al, [fi_k_backspace]  ; backspace
   int 10h		  ; backspace again
 
   jmp .file_get_string_loop   ; go to the main loop
 
 .file_get_string_done:
 
   ret			  ; return from function call

  ; =============
  ; DATA SECTION
  ; =============

  ; boot device
  bootDevice	db 0
  SectorsTrack	dw 18
  Heads 	dw 2

  ; key constants
  fi_k_backspace DB 0x08
  fi_k_enter	 DB 0x0D
  ; print constants
  fi_k_newline	 DB 0x0D, 0x0A, 0

  ; buffer for keyboard input for file search
  filenameBuffer rb 11 ; 11 since name is 8 byte, ext 3 byte
  resr1231231231 db 0  ; 0 so we can print buffer without adding a 0 terminator
  filenameLen	 db 11
  pointer dw 0 ; pointer for buffer
  cluster dw 0 ; cluster temp for loading file

  file_read_succes db 0

  ; where we will read the file
  readAtEX	dw 0 ; ex will be something like 3000h, 4000h etc