; Created by Lazu Ioan-Bogdan

 ; string, print utilitaries

 ; ================
 ; string compare

 ; load SI, DI with the desired strings for this instruction
 ; trashed ax, bx, si, di
 ; sets carry on succes, false otherwise
 ; ================
 strcmp:
 .strcmp_loop:
   mov al, [si]   ; grab a byte from SI
   mov bl, [di]   ; grab a byte from DI
   cmp al, bl	  ; test them
   jne .notequal  ; jne = jump not equal(ZF != 0)
 
   cmp al, 0
   je .done
 
   inc di     ; increment DI
   inc si     ; increment SI
   jmp .strcmp_loop  ; loop
 
 .notequal:
   clc	; not equal, clear the carry flag
   ret
 
 .done: 	
   stc	; equal, set the carry flag
   ret

 ; ================
 ; print char function

 ; prints a single char
 ; al must be loaded with the char to print
 ; ================
 print_char:
   mov ah, 0x0E
   int 0x10

   ret


 ; ================
 ; print string function

 ; SI must be loaded with the pointer for lodsb
 ; to the string to be printed
 ; =================
 print_string:
 .print_string:

   lodsb	     ; grab a byte from SI and put it in AL

   or AL, AL	     ; logical or AL by itself(or instead of CMP
		     ; since it's faster than CMP AL,0)
   jz .print_done    ; if the result is zero, get out
		     ; (recap jz jumps if ZF = 0)
 
   mov AH, 0x0E      ; telnet print is when AH is 0x0E
   int 0x10	     ; print out the character (if we are not jz-ed)
 
   jmp .print_string ; jumps backwards and prints again
 
 .print_done:
   ret		     ; return from 'function' call


 ; ================
 ; print number in hexadecimal function

 ; AX must be loaded with the number to print
 ; SI, AX, BX, CX are trashed
 ; ================
 print_ax:
   mov SI, table_hexa

   xor BX, BX		  ; clean up BX

   mov CX, AX		  ; move AX in CX so we can use AX for print
   mov [g_btemporary], CH ; move CX in a temp variable
			  ; for later use of nibbles

   shr CH, 4		  ; put in CH the upper nibbles of CH
   mov BL, CH		  ; load BX with the displacement
   mov AL, [SI + BX]	  ; move in AL the value from the table

   mov AH, 0x0E 	  ; teltype print
   int 0x10		  ; call the BIOS interupt

   mov CH, [g_btemporary] ; move again in CX
   ror CH, 4		  ; this part is done so we
   shr CH, 4		  ; can loose the upper part and have only the lower one

   mov BL, CH		  ; mov in BL the value from CH

   mov AL, [SI + BX]	  ; load the displaced value
   mov AH, 0x0E 	  ; teltype print
   int 0x10

   mov [g_btemporary], CL ; move CL in g_btemporary for later use
   shr CL, 4		  ; now the same thing above with CL part
   mov BL, CL		  ; move the value in BL

   mov AL, [SI + BX]	  ; same, load displacement
   mov AH, 0x0E 	  ; teltype print
   int 0x10

   mov CL, [g_btemporary] ; load from the temp var
   ror CL, 4		  ; get rid of the upper part
   shr CL, 4		  ; put the bytes in the normal order
   mov BL, CL		  ; load BL with the CL value

   mov AL, [SI + BX]	  ; load with displacement
   mov AH, 0x0E 	  ; teltype print
   int 0x10

   ret

 ; ================
 ; print number in hexadecimal function

 ; AX must be loaded with the number to print
 ; AX, BX, CX are trashed
 ; ================
 print_al:
  mov si, table_hexa

  mov [g_btemporary], al

  shr al, 4
  movzx bx, al
  mov al, [si + bx]
  mov ah, 0x0E
  int 0x10

  mov al, [g_btemporary]

  ror al, 4
  shr al, 4
  movzx bx, al
  mov al, [si + bx]
  mov ah, 0x0E
  int 0x10

  ret


  ; ================
  ; print ax in decimal

  ; AX must be loaded with the number to print
  ; AX, BX, CX are trashed
  ; ================
 print_ax_decimal:

   mov si, table_decimal    ; move in the decimal table

 .loop_ax_decimal:
   xor dx, dx		    ; we 0 dx
   div word [ten]	    ; divide by ten
   mov [g_stringwtemp], ax  ; store qotient

   mov bx, dx		    ; move in bx the displacement

   mov al, [si + bx]	    ; get which char from the table to print
   mov ah, 0x0E 	    ; teltype print
   int 0x10		    ; int 10h

   mov ax, [g_stringwtemp]  ; get quotient
   cmp ax, 0		    ; it it's zero return
   jnz .loop_ax_decimal     ; else loop again

   ret

  ; ================
  ; DATA SECTION
  ; ================
  g_btemporary RB 1
  g_stringwtemp RW 1

  ; table from where to get the value of a nibble
  ; we are going
  ; we are going to get only the displacements from the
  ; upper-lower nibbles of AH,AL load them in the number
  ; buffer and print them
  table_hexa DB '0123456789ABCDEF'
  table_decimal db '0123456789'

  ten dw 10


