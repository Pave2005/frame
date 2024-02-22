.model tiny

.data
;===============================================================================
; 0 - variable frame
; 1 - double frame
; 2 - love frame
; 3 - single frame
; 4 - rounded frame
; 5 - arithmetic frame
;
; $ - text string end symbol.
; \ - new line transition symbol.
;===============================================================================

FrDescrArray db  00h,  00h,  00h,  00h, 00h,  00h,  00h,  00h,  00h 	     ; 0
		     db 0c9h, 0cdh, 0bbh, 0bah, 20h, 0bah, 0c8h, 0cdh, 0bch 		 ; 1
		     db  03h,  03h,  03h,  03h, 20h,  03h,  03h,  03h,  03h 		 ; 2
		     db 0dah, 0c4h, 0bfh, 0b3h, 20h, 0b3h, 0c0h, 0c4h, 0d9h 		 ; 3
		     db  2fh, 0c4h,  5ch, 0b3h, 20h, 0b3h,  5ch, 0c4h,  2fh 		 ; 4
		     db  2bh,  2dh,  2bh, 0b3h, 20h, 0b3h,  2bh,  2dh,  2bh 		 ; 5

StringArray  db  50  DUP(0)

.code
.286
org 100h
;-------------------------------------------------------------------------------
space     		equ 20h
bttm_line 		equ 00h
top_line 		equ 01h
mid_line 		equ 02h

top_left_angl   equ   0
top_fr_line     equ   1
top_right_angl  equ   2
left_fr_side    equ   3
inner_place     equ   4
right_fr_side   equ   5
bttm_left_angl  equ   6
bttm_fr_line 	equ   7
bttm_right_angl equ   8

fr_code 		equ   4
colour 			equ   6
height 			equ   8
fr_width 		equ  10

shadow_colour 	equ 56h

descr_len 		equ   9

end_of_string   equ '$'
;-------------------------------------------------------------------------------
;===============================================================================
;Labels that return the character code that should be printed in the one part
;of the frame.
;
;Used registers:	bx - address of the cell from the array with the
;			     		 characteristics of the frame that stores the
;			     		 symbol that is contained on the left side of the
;			     		 frame.
;					ax - the register in which the offset is stored to the
;			     		 beginning of the part with the pattern of a
;			     		 certain frame.
;					cx - offset to the cell with symbol code.
;-------------------------------------------------------------------------------
.GetFrArrSym	macro

				push bx
				lea bx, FrDescrArray
				add bx, ax
				add bx, cx
				xor ax, ax
				mov al, [bx]
				pop bx

				endm
;-------------------------------------------------------------------------------
.SetVidMemAddr  macro

				mov dx, 0b800h
				mov es, dx

				endm

.GetCmdLineSym  macro

				mov ah, es:[bx]
				call SkipSpaces

				endm


.GetDecNumPart  macro

				sub ah, '0'
				mov al, ah
				mov cl, 10
				mul cl

				endm

;===============================================================================
;This macros, depending on the value of the di register, transmits a character
;to the al register, which should be drawn in the one of the parts of the frame.
;
;Used registers:			di - stores the value of the frame string mode.
;
;Labels:             NotTopSym - the label after which the top frame
;					   		     symbol is not returned.
;			        NotBttmSym - the label after which the bottom
;					   		     frame symbol is not returned.
;			     FinishSetCode - the label that returns the program to
;					   		     the end of macros.
;
;Input arguments:		    ax - offset to the beginning of the frame pattern.
;					top_fr_sym - offset to array cell that contains the
;								 symbol of the top of the frame.
;				   bttm_fr_sym - offset to array cell that contains the
;								 symbol of the bottom of the frame.
;				 middle_fr_sym - offset to array cell that contains the
;								 symbol of the middle of the frame.
;
;Returned value:	        al - symbol of the frame line.
;-------------------------------------------------------------------------------
.SetSymCode 	macro top_fr_sym, bttm_fr_sym, middle_fr_sym, NotTopSym, NotBttmSym, FinishSetCode

				cmp di, top_line
				jne NotTopSym

				mov cx, top_fr_sym
				.GetFrArrSym
				jmp FinishSetCode

NotTopSym: 		cmp di, bttm_line
				jne NotBttmSym

				mov cx, bttm_fr_sym
				.GetFrArrSym
				jmp FinishSetCode

NotBttmSym:		mov cx, middle_fr_sym
				.GetFrArrSym

FinishSetCode:
				endm
;-------------------------------------------------------------------------------
jmp Main
;===============================================================================
;This function checks for parity the number that lies in the ax register.
;
;Used registers: 	ax
;
;Increases the ax value by 1 if it is odd.
;-------------------------------------------------------------------------------
MakeEven    proc

			test ax, 1
			jnz OddNum
			jmp EvenNum

OddNum:		inc ax

EvenNum:	ret

endp
;===============================================================================
;This function prints the specified text in the frame.
;
;Used registers:	bp - position of the top of the stack from which the
;			     	     parameters lying in the stack is reported.
;					bx - address of the symbol in the array.
;			   		   - number of cells to the first character of the text
;			             from the beginning of the video memory.
;					ch - string length counter.
;					cl - counter of the number of lines of text.
;					ax - offset from the edge of the screen to the
;			     		 beginning of the text.
;			   		   - number of cells to the line in which the text
;			     		 begins.
;			   		   - temporary place of number of cells to the first
;			     		 character of the text from the beginning of the
;			     		 video memory.
;					cx - offset to the line with the beginning of the text.
;			   		   - address of the symbol in the array.
;					al - symbol from an array with text.
; 					dl - color code.
;					dx - offset from the beginning of video memory to the
;			     		 text string we need.
;-------------------------------------------------------------------------------
PrintText		proc

				push bp
				mov bp, sp

				xor cx, cx
				xor bx, bx
				xor ax, ax
				xor dx, dx

				lea bx, StringArray 			; bx = array addr

CountStringLen:	mov dl, [bx]
				cmp dl, end_of_string
				je EndStrSym 					; len of string in cx

		    	inc bx
				inc ch							; len counter
				cmp dl, '\'
				je TextStrNum
				jmp CountStringLen

TextStrNum: 	inc cl
				jmp CountStringLen

EndStrSym: 		mov ax, 80
				sub al, ch 						; ax = shift to start of pct

				call MakeEven  					; odd number

	 			push ax
				mov ax, [bp + height]			; ax = height
				sub al, cl
				sub ax, 1
				xor bx, bx
				mov bl, 2
				div bl 							; ax =  middle of height

				add ax, 1 						; shift to top of text
				mov cx, ax

				xor ax, ax

				mov al, 160
				mul cl							; ax = start line of middle

				xor bx, bx
				mov bx, ax

				pop ax

				add ax, bx 						; shitf to start point of text

				call MakeEven

				mov bx, ax

				xor cx, cx
				xor ax, ax

				lea cx, StringArray

				mov dx, bx

Printing:		push bx
				mov bx, cx
				mov al, [bx]
				pop bx

				cmp al, end_of_string
				je SkippedPlace
				cmp al, '\'
				jne GoToPrinting

		 		add dx, 160
				mov bx, dx

				jmp Continue

GoToPrinting:	push dx
				mov dl, [bp + colour]
				mov byte ptr es:[bx],     al
				mov byte ptr es:[bx + 1], dl
				pop dx

Continue:		add bx, 2
				inc cx
				jmp Printing

SkippedPlace:	pop bp
				ret

				endp
;===============================================================================
;This function draws an empty part of the frame on the screen, that is, a
;a coloured line.
;
;Used registers:	dx - takes the intermediate value of the video memory
;			     		 start address and passed it to the es register.
;					es - stores the start address of the video memory.
;					dl - stores the colour code of the frame element.
;					cx - stores the width of the frame.
;					bx - the number of the video memory cell in which the
; 			     		 the symbol should be placed.
;
;Input arguments:	bx - transmitted in the frame drawing function.
;
;Return value:		bx - incresed value by the width of the frame, given
;			     		 that each symbil occupies two cells.
;-------------------------------------------------------------------------------
DrawEmptyLine	proc

				push cx
				push dx

				.SetVidMemAddr
				mov dl, [bp + colour]			; color

				mov cx, [bp + fr_width]			; ax = width

PrintLine:		mov byte ptr es:[bx],  space
				mov byte ptr es:[bx + 1], dl 	; color
				add bx, 2
				loop PrintLine

				pop dx
				pop cx

				ret
				endp
;===============================================================================
;This function draws a string with a frame pattern.
;
;Used registers: 	ax - offset to the first code of a certain frame in
;			     		 array.
;					dx - intermediate storage location of the video memory
;			     		 start address.
;					es - video memory start address.
;					dl - color code.
;					cx - length of the inner part of the frame.
;					bp - the start of the reference in the stack, from
;			     		 which the places of the arguments specified in the
;			     		 main function are counted.
;					si - the end of the stack.
;					bx - offset from the start of the video memory to the
;			     		 cell in which the symbol should be placed.
;
;Input arguments:	bx
;					bp
;
;Return value:		bx - offset changed to the length of the frame string.
;-------------------------------------------------------------------------------
DrawFrLines 	proc

				push cx
				push dx

				.SetVidMemAddr
				mov dl, [bp + colour]			; color

				mov byte ptr es:[bx],    space
				mov byte ptr es:[bx + 1],   dl

				mov si, sp
				mov ax, [si + 8]				; ax - shift to 1 elem of
												; array string

				; select a symbol for the left side of the frame
				.SetSymCode top_left_angl, bttm_left_angl, left_fr_side, NotTopLAngle, NotBttmLAngle, FinishL

				mov byte ptr es:[bx + 2],   al 	; angle code in video mem
				mov byte ptr es:[bx + 3],   dl 	; color code in video mem

				mov si, sp
				mov ax, [si + 8]

				; select a symbol for the middle part of the frame
				.SetSymCode top_fr_line, bttm_fr_line, inner_place, NotTopLine, NotBttmLine, FinishLines

				mov cx, [bp + fr_width]			; width of frame
				sub cx, 4

				add bx, 4						; bx = bx + 4 start of --
				mov dl, [bp + colour]			; al = color code

PrintFrameTop:	mov byte ptr es:[bx],       al	; -- code in vid mem
				mov byte ptr es:[bx + 1],   dl 	; color code in vid mem
				add bx, 2
				loop PrintFrameTop

				mov si, sp
				mov ax, [si + 8]				; start cell idx in frame code

				; select a symbol for the right side of the frame
				.SetSymCode top_right_angl, bttm_right_angl, right_fr_side, NotTopRAngl, NotBttmRAngl, FinishR

				mov dl, [bp + colour]			; color code

				mov byte ptr es:[bx],       al
				mov byte ptr es:[bx + 1],   dl

				mov byte ptr es:[bx+ 2], space 	; space code
				mov byte ptr es:[bx + 3],   dl

				pop dx
				pop cx

				ret
				endp
;===============================================================================
;This function draws a frame depending on the arguments passed on the command
;line.
;
;Used registers:	ax - offset from the edge of the screen to the edge of
;			     		 the frame.
;					cx - temporarily stores the width of the frame.
;			  		   - at the begininning of the program, it takes the
;			     		 value of the frame height, at the end it is reset
;			     		 thus the program draws the frame element in the loop.
;					dx - stores the value of the frame height, because of
;			     		 this, when the value of the cycle counter is
;			     		 compared with dx, a certain frame element is drawn.
;					al - contains offset in bytes from the top edge of the
;			     		 screen to the beginning of a certain line of the frame.
;					bx - offset along the edge of the beginning of the
;			     		 frame line.
;					si - pointer to the start of the stack.
;
;Input arguments:	0
;
;Return value:		bx - depending on the line you want to draw, it changes
;			     	     its value.
;					cx - reset in the cycle.
;-------------------------------------------------------------------------------
DrawFrame		proc
				push bp 						; stack pointer to pushed elems
				mov bp, sp

				push ax							; shift to 0 elem of string in
												; array

				mov ax, 80
				mov cx, [bp + fr_width]			; width
				sub ax, cx  					; ax = Start place of farme
				call MakeEven

				push ax  						; 1 elem of frame line
				xor ax, ax
				xor cx, cx
				mov cx, [bp + height]			; height of picture
				mov dx, cx 						; dx = height

PrintCollmn:	mov al, 160
				mul cl
				mov bx, ax 						; bx = idx of 0 elem in our line
				xor ax, ax

				mov si, sp						;[sp] = ax - shift 20
				add bx, [si] 					; start printing place
												; bx = bx + 20

				cmp cx, dx
				jne NotBEmptyLine

				call DrawEmptyLine
				jmp Finish

NotBEmptyLine:	cmp cx, 1
				jne NotTEmptyLine

				call DrawEmptyLine
				jmp Finish

NotTEmptyLine:	cmp cx, 2
				jne NotFrameTop

				mov di, top_line
				call DrawFrLines
				jmp Finish

NotFrameTop:	sub dx, 1
				cmp cx, dx
				jne NotFrameBttm

				add dx, 1
				mov di, bttm_line
				call DrawFrLines
				jmp Finish

NotFrameBttm:	add dx, 1

				mov di, mid_line
				call DrawFrLines

Finish:			loop PrintCollmn

				pop ax 							; shift to start place of frame
				pop ax 							; 1 elem in array in frame code
				pop bp

				ret
				endp
;===============================================================================
;This function draws a shadow from the frame.
;
;Used registers:	bp - address in teh stack from which the arguments are
;			     		 counted from the command line.
;					ax - initial shadow cell in the row.
;			   		   - offset from the edge of teh screen to the starting
;			     		 point of the lower shadow.
;					bx - full offset to the shadow element from the
;			     		 beginning of the video memory.
;			   		   - line offset to the bottom of teh shadow.
;					cx - number of lines in the side of the shadow.
;			   		   - length of the bottom of the shadow.
;					es - beginning of the video memory.
;					dl - number of the lines to the bottom of teh frame.
;
;Input arguments:	es
;
;Return value:		bx
;-------------------------------------------------------------------------------
DrawShadow 		proc
				push bp
				mov bp, sp

				.SetVidMemAddr

				mov ax, 80
				add ax, [bp + fr_width]			; (160 - (80 - width))

				call MakeEven 					; start x position of shadow

				mov bx, (160 * 2)				; start y position of shadow

				add bx, ax 						; full shift

				mov cx, [bp + height]			; cx - height of frame
				sub cx, 1						; height of shadow part

PrintSidePart:	mov byte ptr es:[bx + 1], shadow_colour
				add bx, 160
				loop PrintSidePart

				mov dl, [bp + height]
				add dl, 1						; y shift

				mov ax, 160
				mul dl
				mov bx, ax 						;shift

				mov ax, 80
				sub ax, [bp + fr_width]
				add ax, 2						; 2 = 1 video elem

				call MakeEven

				add bx, ax

				mov cx, [bp + fr_width]

PrintBttmPart:	mov byte ptr es:[bx + 1], shadow_colour
				add bx, 2
				loop PrintBttmPart

				pop bp

				ret
				endp
;===============================================================================
;This function skips the cells in the command line occupied by spaces between
;the arguments.
;Recursive is included in the function if the next character is also a space.
;
;Used registers:	ah - the value of the byte in the command line.
;					bx - offset from th ebeginning of the command line.
;					es - comand line start address.
;
;Input arguments:	ah - transmitted from DrawFrame function.
;					bx
;
;Return value:		ah - in the SkipedSpaces label changes ah value to the
;			     		 next byte, if there is a space in the current one.
;					bx - increases by one if there is a space in the cell.
;-------------------------------------------------------------------------------
SkipSpaces 		proc

				cmp ah, space  					; space
				jne SkipedSpace

				inc bx
				mov ah, es:[bx]
				call SkipSpaces

SkipedSpace: 	ret
				endp
;-------------------------------------------------------------------------------
WriteFrCode: 	inc bx
				push cx
				push ax
				push dx

				lea dx, FrDescrArray

				mov cx, descr_len
				mov ax, 0

WriteInArr: 	push cx

				mov cl, es:[bx]

				push bx

				mov bx, dx
				add bx, ax
				mov [bx], cl

				pop bx

				inc ax
				inc bx
				pop cx
				loop WriteInArr

				pop dx
				pop ax
				pop cx

				jmp FinishWrite
;===============================================================================
;This function transfers the text to be framed in the array StringArray.
;
;Used registers:	dx - temporarily stores the start address of the array.
;					bx - offset from the beginning of the command line to
;			     		 the desired character.
;			   		   - depending on the cell in which the code needs to
;			     		 be placed, bx changes value.
;					ah - text symbol from the command line.
;					cx - offset from the beginning of the array with text.
;Input arguments:	ah
;					bx
;Return value:		bx - increased offset value to the final character of
;			     		 the command line.
;					ah - end of text symbol.
;-------------------------------------------------------------------------------
ScanString 		proc

				push cx
				push dx

				lea dx, StringArray
				push bx
				mov bx, dx
				mov [bx], ah
				pop bx

				cmp ah, end_of_string
				je Skip

				mov cx, 1
				inc bx

ReplaceString:	mov ah, es:[bx]

				push bx
				mov bx, dx
				add bx, cx
				mov [bx], ah
				pop bx
				inc bx
				inc cx
				cmp ah, end_of_string
				jne ReplaceString

Skip:   		pop dx
				pop cx

				ret
				endp
;===============================================================================
;This function accepts command line arguments, puts teh characteristics of the
;frame in the registers dl, dh, cl, ch. And the text in the array.
;
;Used registers:	ah - function number to get the memory segment in which
;			     		 the command line is stored.
;			   		   - symbil code from the command line.
;					al - command line element code.
;			   		   - decimal part of the command line parameter.
;					es - the address of the segment where the command line
;			     		 is stored.
;					bx - offset to the character of the command line.
;					dl - width of the frame.
;					dh - height of the frame.
;					ch - colour of the frame.
;					cl - frame code.
;
;Return value:		dl
;					dh
;					ch
;					cl
;-------------------------------------------------------------------------------
HandleCmdLine 	proc

				mov ah, 62h
				int 21h
				push bx
				pop es 							; segment addr of cmd line

				mov bx, 81h

				.GetCmdLineSym  				; ah = symbol

				.GetDecNumPart					; ah = char symbol

				inc bx
				.GetCmdLineSym

				sub ah, '0'
				add al, ah

				mov dl, al 						; dl = width
;_______________________________________________________________________________
				inc bx
				.GetCmdLineSym

				.GetDecNumPart

				inc bx
				.GetCmdLineSym

				sub ah, '0'

				add al, ah 						; height of frame

				mov dh, al 						; dh = height
;_______________________________________________________________________________
				inc bx

				.GetCmdLineSym

				sub ah, '0'
				mov al, ah
				mov cl, 100
				mul cl
				mov ch, al

				inc bx
				.GetCmdLineSym

				.GetDecNumPart

				inc bx
				.GetCmdLineSym

				sub ah, '0'

				add ch, al
				add ch, ah  					; ah = color code
;_______________________________________________________________________________
				inc bx
				xor cl, cl

				.GetCmdLineSym

				cmp ah, '*'
				je BufWriteFrCode

				sub ah, '0'

				mov cl, ah 						; cl = frame code

				inc bx
FinishWrite: 	.GetCmdLineSym

				call ScanString

				ret
				endp
;-------------------------------------------------------------------------------
BufWriteFrCode:	jmp WriteFrCode
;===============================================================================
Main: 	mov ax, @data
		mov ds, ax
		xor ax, ax

		call HandleCmdLine
		xor ax, ax

		mov al, dl								; width
		push ax

		mov al, dh 								; height
		push ax

		mov al, ch 								; color code
		push ax

		mov al, cl 								; frame code
		push ax

		xor cx, cx
		xor dx, dx
		xor ax, ax

		mov bp, sp 								; frame code
		mov ax, [bp]
		mov cl, descr_len
		mul cl									; ax = shift 1 elem of string

		call DrawFrame

		call PrintText

		call DrawShadow

end		Main
