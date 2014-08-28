 ; Created by Lazu Ioan-Bogdan

 ; all PC BIOS must place a boot strap code at 07C0:0000
 ; don't forget... some BIOSes jump to 07C0:0000 instead of
 ; 0000:7C00
 ; now we must assure the code segment and data segment
 ; and extra segment and any other segments are set up
 ; corectly
 ; now instead of being happy and just playing with offsets
 ; we have to be extra carefull to set segments and such too

 ; This buffer is the address of the finish of the
 ; bootloader. There we will load the temp data from the
 ; diskette (like root dir) when we do operations with it
 ; Move it up, up so we can load our stage 2
 ; kernel here so we can jump there with 0x0:ADDRESS
 ; so we can load the gdt
 ; Buffer at 57343(DFFF) real address
 ; From 31744 to 57343 we have free space
 ; Real = 7c00+63FF = 57343
 buffer equ 0x63FF;200h

 ; (for some usefull interupts see RB's inter list)

use16

   ; NOTE: these make part of the boot sector header (3 bytes)
   jmp short start ;
   nop		   ; so we have 3 bytes


;=============================
; DISK DESCRIPTIOR START
;=============================

; disk desctiption. See Notebook for details
OEMLabel		db "XJOSBOOT"	; My OS name (8 bytes)
BytesPerSector		dw 512		; Bytes per sector
SectorsPerCluster	db 1		; Sectors per cluster
					; (from now on we are going to
					; use sector/cluster interchangely
					; since they are equal in fat12)
ReservedSectors 	dw 1		; Reserved clusters for boot record
FATTablesCount		db 2		; Number of copies of the FAT
RootEntries		dw 224		; Number of files/subdirectories in root dir
					; 14 sectors * 512 = 7168 bytes
					; / 32 = 224 max entries(must load 14 sects)
					; (1 dir entry has 32 bits)
TotalSectorCount	dw 2880 	; Number of logical clusters
MediaDescription	db 0F0h 	; Media description
SectorsPerFat		dw 9		; Clusters per FAT
SectorsTrack		dw 18		; Clusters / track
Heads			dw 2		; Number of heads (or sides)
HiddenSectors		dd 0		; Number of hidden sectors
LargeSectors		dd 0		; Sector stuff for fat 32(ignore in 12/16)
DriveNr 		dw 0		; Drive Nr: 0 (unused)
BootSignature		db 0x29 	; Drive signature: 0x29
VolumeID		dd 00000000h	; Usually date
VolumeLabel		db "XJOS       "; Volume Label: 11 chars. Will
					; be used by the root directory
FileSystem		db "FAT12   "	; File system type. Not used by
					; most OSes to determime filesystem
					; type because in many casses it is not
					; pressent or it contains invalid data
					; But to be sure we put it here because
					; MAYBE someone might use it.
					; (see notebook notes)

;=============================
; DISK DESCRIPTOR END
;=============================

; ================
; START OF BOOTSTRAP CODE
; ================

start:
   ; set origin to 0x7c00(real address)
   mov ax, 0x7C0   ; set up segments (07c0 = 1984 in decimal)
		   ; where the BIOS throws us

   add ax, 544	   ; we add 544 here because (544 * 16 = 8704 / 1024 = 8K)
		   ; we must leave a 8kb buffer after our code for
		   ; loading the 14 sectors of root directory

   cli		   ; disable interupts while setting stack
   mov ss, ax	   ; stack 0x7C0(hexa) + 544(decimal)
   mov sp, 4096    ; top of the stack. We have 4kb for stack(a lot...)
		   ; (top = ss + sp)
   sti		   ; set interupts

   mov ax, 0x7C0   ; set again
   mov ds, ax	   ; data segment

   ; Don't forget!
   ; A diskete has: 80 sectors(512 bytes each), 10 tracks, 2 heads
   ; 40 sectors for 1 head, 5 tracks per head
   ; a track is like a circular slice of the diskete
   ; a sector is the smallest part of it
   ; a head is the front or the back of the diskete

   ; as we know(see notebook) the root dir starts at logical sector 19
   ; and it is 14 sectors long(14 * 16 = 224 max entries)

   mov ax, 19
   call logical_to_hts	; convert from logical to head/track/sector

   mov si, buffer  ; our 8kb buffer(14 * 512 = 7168 (aprox 8kb that we reserved))
   mov bx, ds	   ; get data segment
   mov es, bx	   ; so ES points to the right location
   mov bx, si	   ; and now ES:BX is (current ES:diskette_buffer)

   mov ah, 2	   ; int for read sectors
   mov al, 14	   ; read 14 sectors

   pusha	   ; push all general registers, prepare to enter loop

read_root_dir:
   popa 	   ; case regs are altered
   pusha	   ; in case regs are altered

   stc		   ; not set on error on some bioses
   int 13h

   jnc search_dir  ; if carry not set we're succesfull
   call reset_diskette
   jnc read_root_dir

   jmp reboot	   ; on double error just reboot

search_dir:
   popa 	   ; get all our registers back

   mov di, buffer  ; now DI points to our buffer...

   mov cx, word [RootEntries]	 ; move in acumulator max nr of entries(224)
   mov ax, 0			 ; offset it 0 now (we will jump from 32 to 32 bytes
				 ; since a file's data is stored in 32 bytes)

next_root_entry:
   xchg cx, dx			 ; use dx as a cache
   
   mov si, kern_filename	 ; our kernel filename(XKERNEL.BIN)(XKERNEL BIN)
   mov cx, 11			 ; filename is 11 ascii chars long
				 ; so we neet to loop 11 times to compare all bytes
   rep cmpsb			 ; rep cmpsb = hardware repeat compare string byte

   je found_file_to_load	 ; if they're all equal we cound the kernel
				 ; (DI will be at offset 11)
   ; else we didn't found it
   add ax, 32			 ; 32 more bytes add for next file entry

   mov di, buffer		 ; move again since it is trashed by rep cmpsb
   add di, ax			 ; add it by new offset
				 ; (will be 0, 32, 64, 96, 128, etc)

   xchg dx, cx			 ; get old CX back from it's DX cache
   loop next_root_entry 	 ; if CX is not 0 loop again

   ; else print not found message and reboot
   mov si, msg_not_found
   call print_string
   jmp reboot


found_file_to_load:	     ; we fount kernel
   mov ax, word [es:di+15]   ; from the docs(see notebook) we know the first
			     ; cluster from a file is from byte 26 to byte 28
			     ; from 28 to 32 we have file size in bytes

   mov word [cluster], ax    ; store first cluster position
			     ; at this moment we got the good cluster to load

   mov ax, 1		     ; FAT table starts at sector 1
   call logical_to_hts	     ; for calculating sector in head/track/sector

   mov bx, buffer	     ; now ES:BX point to buffer again

   mov ah, 2		     ; bios interrupt
   mov al, 9		     ; read ALL fat table(we know from docs it's
			     ; 9 sectors big)

   pusha		     ; prepare for read loop


read_fat:
   popa
   pusha

   stc
   int 13h

   jnc read_fat_ok	     ; if were ok proceed
   call reset_diskette	     ; else reset floppy
   jnc read_fat 	     ; else again try read

   call fatal_error	     ; if we got double error reset

read_fat_ok:		     ; now we have FAT in diskette_buffer
			     ; don't forget [cluster] also contains
			     ; the value we have to load
   popa 		     ; restore registers

   mov ax, [loadAt]		; we load at 2000H
   mov es, ax
   mov bx, 0		     ; ES:BX = 2000H:0H (there we will have our kernel)

   mov ah, 2		     ; for int 13h read floppy
   mov al, 1		     ; we will always read only 1 sector
			     ; (we read 1 sector at the time because of
			     ; the fragmentation (see notebook))

   push ax		     ; so we don't trash it (we save ah 2 and al 1)
			     ; will be the same for all sector reads

load_xkern_sector:
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
   call logical_to_hts	    ; convert logical to real

   mov ax, [loadAt]	       ; location where we will load
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
   jnc calculate_next_cluster
   call reset_diskette	    ; else reset floppy
   jmp load_xkern_sector    ; and after reset try again... until we suceed


   ; since FAT entries are 12 bytes it is a little difficult to extract
   ; a single value since 2 entries are packed in 3 bytes
   ; formula fo calculating a single entry
   ; *if entry is even:
   ; - low four bits of upper 12 bits: 1 + (3 * n) / 2 (have to mask the upper bits)
   ; - normal other 8 bits of lower 12 bits: (3 * n) / 2
   ; *if entry is odd:
   ; - high four bits of lower 12 bits: (3 * n) / 2 (have to mask lowe bits)
   ; - normal other 8 buits of upper 12 bits: 1 + (3 * n) / 2
   ; see notebook for details

calculate_next_cluster:
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

   mov si, buffer	   ; get diskette buffer in SI
   add si, ax		   ; we have fat entry position
   mov ax, word [ds:si]    ; load in AX the actual entry (2 bytes, 16 bits, 1 word)
			   ; note that we still must mask some bits that
			   ; should not be there
   or dx, dx		   ; see odd/even (if DX = 0 even else odd)
   jz cluster_even

cluster_odd:
   shr ax, 4		   ; shift right the first 4 bits since they
			   ; belong to some other entry
   jmp short cluster_next  ; get over cluster even

cluster_even:
   and ax, 0FFFh	   ; mask final 4 bits(bits are read right to left dont
			   ; forget that

cluster_next:
   mov word [cluster], ax  ; move in [cluster] the content of [cluster]
			   ; (since for the first time it held only
			   ; the position of the first cluster)

   cmp ax, 0FF8h	   ; the 0FF8 is the end of file marker in fat12/16
			   ; and 0FFF is end of EOC(end of clusterchain)
   jae .end		   ; if it's the last cluster we're done YEY!
			   ; don't forget jae (above equal) since all
			   ; that is above 0FF8h is EOF/EOC

   ; else we update buffer pointer by 1 sector length and we jump again...
   add word [pointer], 512
   jmp load_xkern_sector

.end:			   ; yey we're done
   mov si, msg_succes	   ; print the succes
   call print_string

   ; give kernel bootdevice in dl
   mov dl, byte [bootDevice]

   ; don't forget to make lib for all this file loading stuff...

   ; TODO: test jump to new location
   jmp 0:0x7e00 	; farjump to kernel's main YEEEEEEEEEY!!!!!
   
 ; ================
 ; FUNCTIONS FOR OUR USE
 ; ================

 ; =================
 ; error function
 ; =================
fatal_error:
   mov si, msg_fatal_error
   call print_string
	     

reboot:        ; case we fail we just reboot
   mov ax, 0
   int 16h     ; wait for key
   mov ax, 0
   int 19h     ; restart

 ; ================
 ; print string function

 ; SI must be loaded with the pointer for lodsb
 ; to the string to be printed
 ; AX is destroyed
 ; =================
 print_string:
   pusha
   mov ah, 0Eh	

 .repeat:
   lodsb	     ; grab a byte from SI and put it in AL

   or AL, AL	     ; logical or AL by itself(or instead of CMP
		     ; since it's faster than CMP AL,0)
   jz .print_done    ; if the result is zero, get out
   int 0x10	     ; print out the character (if we are not jz-ed)
 
   jmp short .repeat ; jumps backwards and prints again
 
 .print_done:
   popa
   ret		     ; return from 'function' cal
   
 ; ================
 ; reset floppy function

 ; carry set on error
 ; no registers are trashed
 ; ================
 reset_diskette:
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

 ; ================
 ; logical to head/track/sector

 ; calculates the head/track/sector of a
 ; logical sector for the real disk.
 ; ================

 ; AGAIN TO REMEMBER!
 ; RB's stuff
 ; INT 13 - DISK - READ SECTOR(S) INTO MEMORY
 ;     AH = 02h
 ;     AL = number of sectors to read (must be nonzero)
 ;     CH = low eight bits of cylinder number (track)
 ;     CL = sector number 1-63 (bits 0-5)
 ;          high two bits of cylinder (bits 6-7, hard disk only)
 ;     DH = head number
 ;     DL = drive number (bit 7 set for hard disk)
 ;     ES:BX -> data buffer
 ; Return: CF set on error
 ;         if AH = 11h (corrected ECC error), AL = burst length
 ;     CF clear if successful
 ;     AH = status (see #00234)
 ;     AL = number of sectors transferred (only valid if CF set for some
 ;          BIOSes)

logical_to_hts:
   push bx		       ; save bx, ax which we will sue
   push ax

   mov bx, ax		       ; Save logical sector

   mov dx, 0		       ; first we get the sector
   div word [SectorsTrack]     ; (logical / 63 gives us the sector)
   add dl, 01h		       ; add one since they start at 1 (if logical > 63)
			       ; (we only need the remainder)
   mov cl, dl		       ; get the value from DL (since 63 < 255 we can safely
			       ; say that we only need the lower part of DX)
			       ; CL = sector number for int 13H (see above)
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

   mov dl, byte [bootDevice]   ; set device given to us by BIOS

   ret

 ; ================
 ; END OF BOOTSTRAP CODE
 ; ================

 ; ================
 ; DATA SECTION

 kern_filename db "XKERNEL BIN"
 
 msg_fatal_error db "Disk err. Press key...",0x0D,0x0A,0
 msg_not_found	 db "Kernel not found!", 0x0D, 0x0A, 0
 msg_succes	 db "Succes, kernel found, jumping to it!", 0x0D, 0x0A, 0x0D, 0x0A, 0


 loadAt     dw 0x7e0
 bootDevice db 0 ; boot device number
 cluster    dw 0 ; cluster temp
 pointer dw 0 ; buffer pointer

 ; ================

times 510 - ($-$$) db 0     ; Fill up with zeros
dw	0xAA55		    ; Boot signature(some old bioses need it)

;buffer:                     ; buffer for disk read stuff