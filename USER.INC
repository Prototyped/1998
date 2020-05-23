ArgCount	macro

; This procedure returns the number of arguments.
;
; Call with :-
;
; ES:BX = command tail address
;
; Returns :-
;
; AX = argument number

	push	cx
	mov	ax,1

argc1:	mov	cx,-1

argc2:	inc	bx
	cmp	byte ptr es:[bx],0dh
	je	argc3
	cmp	byte ptr es:[bx],20h
	je	argc1
	cmp	byte ptr es:[bx],09h
	je	argc1

	jcxz	argc2

	inc	ax
	not	cx
	jmp	argc2

argc3:	pop	cx

endm

ArgGet	macro

; This procedure returns the address of a particular argument.
;
; Call with :-
;
; ES:BX = command tail address
; AX = argument number
;
; Returns :-
;
; ES:BX = address of argument
; AX = length of argument

	push	cx
	push	di

	or	ax,ax
	jz	argv8

	xor	ah,ah

argv1:	mov	cx,-1

argv2:	inc	bx
	cmp	byte ptr es:[bx],0dh
	je	argv7
	cmp	byte ptr es:[bx],20h
	je	argv1
	cmp	byte ptr es:[bx],09h
	je	argv1

	jcxz	argv2

	inc	ah
	cmp	ah,al
	je	argv4
	not	cx
	jmp	argv2

argv4:	mov	ax,bx

argv5:	inc	bx
	cmp	byte ptr es:[bx],0dh
	je	argv6
	cmp	byte ptr es:[bx],20h
	je	argv6
	cmp	byte ptr es:[bx],09h
	jne	argv5

argv6:	xchg	bx,ax
	sub	ax,bx
	jmp	argvx

argv7:	xor	ax,ax
	jmp	argvx

argv8:	mov	ax,3000h
	int	21h
	cmp	al,3
	jb	argv7
	mov	es,es:[2ch]
	xor	di,di
	xor	al,al
	mov	cx,-1
	cld

argv9:	repne	scasb
	scasb
	jne	argv9
	add	di,2
	mov	bx,di
	mov	cx,-1
	repne	scasb
	not	cx
	dec	cx
	mov	ax,cx

argvx:	pop	di
	pop	cx

endm

WordToHex	macro

; This procedure converts a word to hex ASCII.
;
; Call with :-
;
; AX = hex word
; ES:DI = adress for hex ASCII buffer.
;
; Returns AX, DI, CX destroyed.

	push	ax
	mov	al,ah
	call	byte2hex

	pop	ax
	call	byte2hex
	jmp	w2hend

byte2hex:

; This procedure converts a byte to hex ASCII
;
; Call with :-
;
; AL = hex value
; ES:DI = address for hex ASCII buffer
;
; Returns AX, DI, CX modified

	sub	ah,ah
	mov	cl,16
	div	cl
	call	ascii
	mov	al,ah

ascii:

; This procedure converts a value from 00h to 0Fh to hex ASCII character.
;
; Call with AL = 00h to 0Fh
;
; Returns ES:[DI] = hex byte.

	add	al,'0'
	cmp	al,'9'
	jle	asciix
	add	al,'A'-'9'-1

asciix: stosb
	ret

w2hend:

endm

ByteToHex	macro

; This procedure converts a byte to hex ASCII
;
; Call with :-
;
; AL = hex value
; ES:DI = address for hex ASCII buffer
;
; Returns AX, DI, CX modified

	sub	ah,ah
	mov	cl,16
	div	cl
	call	ascii
	mov	al,ah
	call	ascii
	jmp	short b2hend

ascii:

; This procedure converts a value from 00h to 0Fh to hex ASCII character.
;
; Call with AL = 00h to 0Fh
;
; Returns ES:[DI] = hex byte.

	add	al,'0'
	cmp	al,'9'
	jle	asciix
	add	al,'A'-'9'-1

asciix: stosb
	ret

b2hend:

endm

DoubleToDecimal macro

; This procedure converts a doubleword into decimal.
; Call with:
;
; DI = Last byte of decimal display buffer
; DX:AX = Doubleword to convert
;
; Returns :-
;
; DI = Address of decimal display buffer
; Contents of DX & AX are destroyed.
	
hex2dec: push	bp
	xchg	bp,dx
	mov	bx,000Ah
	mov	cl,30
hex2dec1: xchg	bp,ax
	sub	dx,dx
	div	bx
	xchg	bp,ax
	div	bx
	or	dl,cl
	mov	[di],dl
	dec	di
	cmp	ax,0000
	jnz	hex2dec
	pop	bp

endm

ASCIIToWord	macro

; This procedure converts a doubleword containing hex ASCII into
; a usable binary word.
;
; Call with :-
;
; DS:SI = buffer of hex ASCII
;
; Returns :-
;
; AX = binary word
; BX, CX are destroyed.

	lodsb
	call	hex
	mov	cx,4
	shl	al,cl
	push	ax
	lodsb
	call	hex
	pop	bx
	add	al,bl
	xchg	ah,al
	lodsb
	call	hex
	mov	cx,4
	shl	al,cl
	push	ax
	lodsb
	call	hex
	pop	bx
	add	al,bl
	jmp	short ASCIIToHex_End
hex:
; This procedure converts a hex ASCII byte into its binary number counterpart.
;
; Call with :-
;
; AL = hex ASCII byte
;
; Returns :-
;
; AL = binary number

	cmp	al,'9'
	jg	letter
	sub	al,'0'
	ret

letter: sub	al,'A'-'9'-1
	ret

ASCIIToHex_End

endm

MoveCursor	macro

; This procedure moves the cursor one position forward.
;
; Call with: nothing
;
; Returns: nothing

	push	ax
	push	bx
	push	cx
	push	dx

	mov	ah,0fh
	int	10h
	dec	ax
	mov	cols,ah
	mov	pageX,bh

	mov	ah,8
	mov	bh,pageX
	int	10h
	mov	attrib,ah

	mov	ax,1130h
	sub	bh,bh
	int	10h

	cmp	dl,0
	je	mcurs1

	inc	dx
	mov	rows,dl

mcurs1: mov	ah,3
	int	10h

	cmp	dl,cols
	je	eol

	mov	ah,2
	int	10h

	jmp	pops

eol:	cmp	dh,rows
	je	scroll

	mov	ah,2
	inc	dh
	sub	dl,dl
	int	10h

	jmp	pops

scroll: mov	ax,0601h
	sub	cx,cx
	mov	bh,attrib
	mov	dx,word ptr cols
	int	10h

	mov	ah,2
	mov	dh,rows
	sub	dl,dl
	mov	bh,pageX
	int	10h

pops:	pop	dx
	pop	cx
	pop	bx
	pop	ax

	jmp	movcur_end

cols	db	4Fh
rows	db	18h
attrib	db	17h
pageX	db	0

movcur_end:

endm

FileSize	macro

; This reports the size of a file.
;
; Call with:
;
; DS:DX = segment:offset of filename
;
; Returns:
;
; DX:AX = file size
;

	push	dx
	mov	ah,1ah
	mov	dx,offset DTA
	int	21h
	pop	dx
	mov	ax,4300h
	int	21h
	mov	ah,4eh
	int	21h
	mov	dx,fsize_2
	mov	ax,fsize_1
	jmp	short filesize_end

DTA	db	20 dup (00)
fattr	db	00
ftime	dw	0000
fdate	dw	0000
fsize_1 dw	0000
fsize_2 dw	0000

filesize_end:

endm

DecimalToBinary macro

; This converts decimal values into binary.
;
; Call with AX = decimal value
;
; Returns AL = binary byte

	mov	cl,10
	mov	ch,al
	mov	al,ah
	and	ax,0fh
	mul	cl
	and	ch,0fh
	add	al,ch

endm

BinaryToDecimal macro

; This converts binary values into their respective decimal formats.
;
; Call with:	AX = binary word (upto 0FFFh)
;
; Returns:	DX:AX = decimal doubleword (in buffer format)
;		CX destroyed

	mov	cl,10
	div	cl
	mov	ch,ah
	sub	ah,ah
	mov	cl,16
	mul	cl
	mov	cl,0
	add	ax,cx
	push	ax
	and	ah,0f0h
	mov	cl,4
	shr	ah,cl
	add	ah,30h
	mov	dh,ah
	pop	ax
	and	ah,0fh
	add	ah,30h
	mov	dl,ah
	mov	ch,al
	push	cx
	and	ch,0f0h
	shr	ch,cl
	add	ch,30h
	mov	ah,ch
	pop	cx
	and	ch,0fh
	add	ch,30h
	mov	al,ch
endm

Window	macro

; Makes or clears a window.
; Call with:
; AH = 0 for window build.
; AH = -1 for window clear.
; BH = color/attribute (if AH = 0).
; ES:DI = address for buffer (if AH = 0).
; DS:SI = address for buffer (if AH = -1).
; CX = top left corner.
; DX = bottom right corner.
; Note - Will not automatically draw a border!

	mov	ah,0fh
	mov	pageY,bh

	cld

	mov	xy1,cx
	mov	xy2,dx

	cmp	ah,-1
	je	winclr

	push	bx
	mov	ah,3
	mov	bh,pageY
	int	10h
	mov	curpos,dx

	mov	ah,2
	mov	dx,xy1
	int	10h

win1:	mov	ah,8
	int	10h
	stosw
	mov	ah,3
	int	10h
	mov	cx,xy2
	cmp	dl,cl
	jge	win2

	inc	dl
	mov	ah,2
	int	10h
	jmp	short win1

win2:	cmp	dh,ch
	jge	win3

	inc	dh
	mov	cx,xy1
	mov	dl,cl
	mov	ah,2
	int	10h
	jmp	short win1

win3:	mov	ax,0600h
	pop	bx
	mov	cx,xy1
	mov	dx,xy2
	int	10h
	mov	ah,2
	mov	dx,xy1
	int	10h
	jmp	short winend

winclr: mov	ah,2
	mov	bh,pageY
	mov	dx,cx
	int	10h

winc0:	lodsw
	mov	bl,ah
	mov	ah,9
	mov	cx,1
	int	10h

	mov	ah,3
	int	10h
	mov	ax,xy2
	cmp	dl,al
	jge	winc1

	mov	ah,2
	inc	dl
	int	10h
	jmp	short winc0

winc1:	cmp	dh,ah
	jge	winc2

	mov	ax,xy1
	inc	dh
	mov	dl,al
	mov	ah,2
	int	10h
	jmp	short winc0

winc2:	mov	ah,2
	mov	dx,curpos
	int	10h
	jmp	short winend

curpos	dw	0
xy1	dw	0
xy2	dw	184Fh
pageY	db	0

winend:

endm
