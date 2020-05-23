	page	66,80
	title	SEE: to give a listing of a file.
	name	dump

; By Amit Gurdasani, 1994-96.
; See Version 4
;
; To list a file in various forms.
;
; Creation :-
;
; C> TASM SEE;
; C> TLINK SEE /T;
; C> DEL SEE.OBJ
; C> DEL SEE.EXE
;
; Usage :-
;
; C> SEE <filename[.ext]> [/T] [/C] [/H] [/D] [/E] [/S] [/?]
;
; Use /T for standard DOS TTY listing.
;
; Use /C for Cleaned display.
;
; Use /H for Hexadecimal dump.
;
; Use /D for clean hexadecimal Dump.
;
; Use /E for Eliminating high-bit codes and control codes.
;
; Use /S for Stripping the high bit.
;
; Use /? for Help Message

_TEXT   segment

	org	0100h

	assume cs:_TEXT,ds:_TEXT,es:_TEXT,ss:_TEXT

dump1:	mov	ax,3000h
	int	21h
	cmp	al,0
	je	_exitY

	mov	ah, 0fh
	int	10h
	mov	pageno,bh
	mov	colno,ah

	mov	ax,1130h
	mov	bh,0
	mov	dl,0
	int	10h

	cmp	dl,0
	je	dump15

	mov	rowno,dl
	jmp	short dump15

_exitY:	jmp	exitX

abortY: jmp	abortA

dump15:	mov	ah,9
	mov	dx,offset signon
	int	21h

	mov	ah,8
	mov	bh,pageno
	int	10h

	mov	attrib,ah

	call	argc
	cmp	ax,2
	mov	dx,offset syntax
	mov	cx,sy_len
	jb	abortY
	
	cmp	ax,3
	jne	jump1

	mov	ax,2
	call	argv
	mov	dx,[bx]
	cmp	dl,'/'
	jne	invarg
	or	dh,32
	cmp	dh, 's'
	jne	switch0
	mov	flag,6
	jmp	short jump1

switch0: cmp	dh,'h'
	jne	switch1
	mov	flag,5
	jmp	hdump1

switch1: cmp	dh,'d'
	jne	switch2
	mov	flag,4
	jmp	hdump1

switch2: cmp	dh,'e'
	jne	switch3
	mov	flag,3
	jmp	short jump1

switch3: cmp	dh,'c'
	jne	switch4
	mov	flag,2
	jmp	short jump1
	
switch4: cmp	dh,'t'
	jne	invarg
	inc	flag
	dec	row
	jmp	short jump1

abort:	jmp	abortA

invarg:	mov	dx,offset argmsg
	mov	cx,ar_len
	jmp	abortA

help:	mov	dx,offset syntax
	mov	cx,sy_len
	jmp	abortA

jump1:	mov	ax,1
	call	argv
	cmp	word ptr [bx],'?/'	; "backwords" (words are stored
	je	help			; backwards, i. e. in reverse order)
	mov	si,ax
	mov	byte ptr [bx+si],0

	mov	ax,3d00h
	mov	dx,bx
	int	21h
	push	ax

	mov	dx,offset opener
	mov	cx,op_len
	jc	abort

	pop	ax
	mov	handle,ax

dump2:	mov	bx,handle
	mov	ah,3fh
	mov	cx,bufsize
	mov	dx,offset fileptr
	int	21h
	mov	dx,offset reader
	mov	cx,rd_len
	jc	abort
	cmp	ax,0
	je	dump3

	mov	cx,ax
	mov	si,offset fileptr

looper:	push	cx
	lodsb
	push	si

	cmp	flag,6
	je	_strip
	cmp	flag,3
	je	_elim
	cmp	flag,2
	je	_clean
	cmp	flag,1
	je	tty

	mov	ah,0ah
	mov	bh,pageno
	mov	bl,3
	mov	cx,1
	int	10h

	call	movcur

jump3:	pop	si
	pop	cx
	mov	ah,1
	int	16h
	jz	jump4

	cmp	ax,011bh
	jne	jump4

	mov	ah,0
	int	16h
	jmp	abortx

jump4:	loop	looper
	jmp	dump2

dump3:	jmp	dumpX

_strip:	jmp	strip
_clean:	jmp	clean
_elim:	jmp	elim

tty:	cmp	al,0ah
	je	lf

	push	ax
	mov	ah,3
	mov	bh,pageno
	int	10h
	inc	dx
	cmp	dl,colno
	jae	ttymore
	pop	ax

ttydisp: mov	ah,2
	mov	dl,al
	int	21h

	jmp	short jump3

ttymore: inc	row
	mov	al,row
	cmp	al,rowno
	jae	lfmore
	pop	ax

	jmp	ttydisp

lf:	inc	row
	mov	al,row
	cmp	al,rowno
	jae	lfmore
	mov	al,0ah
	jmp	short ttydisp

lfmore:	mov	ah,9
	mov	dx,offset morer
	int	21h
	mov	ah,0
	int	16h
	push	ax
	mov	ax,0a20h
	mov	bh,pageno
	mov	bl,3
	mov	cl,colno
	mov	ch,0
	int 	10h
	pop	ax
	cmp	ax,011bh
	je	lfabort
	mov	row,0
	jmp	jump3

clean:	cmp	al,0dh
	je	cr
	cmp	al,09h
	je	short ttydisp
	cmp	al,'~'
	ja	dot
	cmp	al,' '
	jb	dot

	jmp	short ttydisp

dot:	mov	al,'.'
	jmp	short ttydisp

_jump3:	jmp	jump3
lfabort: jmp	abortx

cr:	pop	si
	lodsb
	push	si

	cmp	al,0ah
	jne	cr_1

	mov	ah,2
	mov	dl,13
	int	21h
	mov	dl,10
	int	21h
	jmp	jump3

cr_1:	cmp	flag,2
	je	cr_2

	jmp	short elim
	
cr_2:	push	ax
	mov	ah,2
	mov	dl,'.'
	int	21h
	pop	ax

elim:	cmp	al,0dh
	je	cr
	cmp	al,09h
	je	_ttydisp
	cmp	al,'~'
	ja	_jump3
	cmp	al,' '
	jb	_jump3

_ttydisp: jmp	ttydisp

strip:	and	al, 7Fh
	mov	dl, al
	mov	ah, 2
	int	21h
	jmp	jump3

exitX:	mov	ah,9
	mov	dx,offset lowver
	int	21h
	int	20h

dumpX:	mov	ah,3eh
	mov	bx,handle
	int	21h
	mov	dx,offset closer
	mov	cx,cl_len
	jc	abortA

	mov	ax,4c00h
	int	21h

abortA:	mov	ah,40h
	mov	bx,2
	int	21h

abortx:	mov	ax,4c01h
	int	21h

hdump1:	mov	ax,1
	mov	bx,80h
	call	argv
	mov	si,ax
	mov	byte ptr [bx+si],0

hdump4:	mov	ax,3d00h	; Open file in read-only mode.
	mov	dx,bx		; Get filename
	int	21h		; Let DOS do it.
	mov	dx,offset opener ; Error occurred, go handle it.
	mov	cx,op_len
	jc	abortA
	mov	handle,ax	; No, store handle

disp:	mov	ah,9
	mov	dx,offset hdg
	int	21h
	mov	cx,8

start:	mov	cx_reg,cx
	mov	di,offset fbuff
	mov	cx,16
	mov	al,' '
	rep	stosb

	mov	ah,3fh
	mov	bx,handle
	mov	cx,16
	mov	dx,offset fbuff
	int	21h
	mov	dx,offset reader
	mov	cx,rd_len
	jc	abortA
	mov	cx,cx_reg
	mov	flen,ax
	cmp	ax,0
	je	_dumpC
	push	cx

	mov	di,offset obuff
	mov	cx,obuff_len
	mov	al,' '
	rep	stosb

	mov	di,offset obuff
	mov	ax,fptr
	call	w2a

	xor	bx,bx

	jmp	short disp1

_start:	jmp	start
_dumpC:	jmp	dumpX

disp1:	mov	al,[fbuff+bx]
	mov	di,offset obuff1
	add	di,bx
	add	di,bx
	add	di,bx
	call	b2a

	inc	bx
	cmp	bx,flen
	jne	disp1

	add	word ptr fptr,16

	mov	ah,40h
	mov	bx,1
	mov	cx,obuff_len
	mov	dx,offset obuff
	int	21h

	mov	di,offset fbuff
	xor	bx,bx
	cmp	flag,4
	je	disp3

disp2:	push	bx
	mov	ah,0ah
	mov	cx,1
	mov	bh,pageno
	mov	al,[fbuff+bx]
	int	10h
	mov	row,0
	call	movcur
	pop	bx
	inc	bx
	cmp	bx,16
	je	dispZ
	jmp	short disp2

dispZ:	mov	dl,13
	mov	ah,2
	int	21h
	mov	dl,10
	int	21h

	pop	cx
	loop	_start

	mov	ah,9
	mov	dx,offset morer
	int	21h
	mov	ah,0
	int	16h
	cmp	al,1Bh
	je	_dumpC
	jmp	disp

disp3:	push	bx
	mov	dl,[fbuff+bx]
	cmp	dl,' '
	jb	disp5
	cmp	dl,'~'
	ja	disp5

disp4:	mov	ah,2
	int	21h
	pop	bx
	inc	bx
	cmp	bx,16
	je	dispZ
	jmp	short disp3

disp5:	mov	dl,'.'
	jmp	short disp4

w2a     proc    near

; This procedure converts a word to hex ASCII.        
;
; Call with :-
;
; AX = hex word
; DI = adress for hex ASCII buffer.
;
; Returns AX, DI, CX destroyed. 

	push    ax
	mov     al,ah
	call    b2a

	pop     ax
	call    b2a
	ret

w2a     endp

b2a     proc    near

; This procedure converts a byte to hex ASCII        
;
; Call with :-
;
; AL = hex value
; DI = address for hex ASCII buffer
;
; Returns AX, DI, CX modified

	sub     ah,ah
	mov     cl,16
	div     cl
	call    ascii
	stosb
	mov     al,ah
	call    ascii
	stosb
	ret

b2a     endp

ascii   proc    near

; This procedure converts a value from 00h to 0Fh to hex ASCII character.
;
; Call with AL = 00h to 0Fh
;
; Returns AL = hex ASCII byte

	add     al,'0'
	cmp     al,'9'
	jbe     asciix
	add     al,'A'-'9'-1

asciix: ret

ascii   endp

movcur	proc	near

	push	ax
	push	bx
	push	cx
	push	dx

	mov	ah,3
	int	10h

	inc	dx
	cmp	dl,colno
	jae	eol

	mov	ah,2
	mov	bh,pageno
	int	10h

	jmp	short pops

eol:	cmp	dh, rowno
	jae	scroll
	
	mov	ah,2
	mov	bh,pageno
	inc	dh
	sub	dl,dl
	int	10h
	inc	row

	jmp	short pops

scroll:	inc	row
	mov	al,row
	cmp	al,rowno
	jae	more

	mov	ax,0601h
	sub	cx,cx
	mov	bh,attrib
	mov	dh,rowno
	mov	dl,colno
	int	10h

	mov	ah,2
	mov	dh,rowno
	mov	dl,0
	mov	bh,pageno
	int	10h
	jmp	short pops

more:	mov	ah,9
	mov	dx,offset morer
	int	21h

	mov	ah,0
	int	16h
	push	ax

	mov	ax, 0a20h
	mov	bh, pageno
	mov	bl, 3
	mov	cl, colno
	mov	ch, 0
	int	10h

	pop	ax
	cmp	ax,011bh
	je	prog_exit

	mov	byte ptr row,0
		
pops:	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

prog_exit:

	add	sp,10
	mov	ax,offset dumpX
	push	ax
	ret

movcur  endp

argc    proc    near
	
; This procedure returns the number of arguments.        
;
; Call with :-
;
; ES = command line segment
;
; Returns :-
;
; AX = argument number

	push    bx
	push    cx
	mov     ax,1
	
	mov     bx,0080h

argc1:  mov     cx,-1

argc2:  inc     bx
	cmp     byte ptr es:[bx],0dh
	je      argc3
	cmp     byte ptr es:[bx],20h
	je      argc1
	cmp     byte ptr es:[bx],09h
	je      argc1
	
	jcxz    argc2
	
	inc     ax
	not     cx
	jmp	short argc2
	
argc3:  pop     cx
	pop     bx
	ret

argc    endp

argv    proc    near
	
; This procedure returns the address of a particular argument.
;
; Call with :-
;
; ES = command tail segment
; AX = argument number
; 
; Returns :-
;
; ES:BX = address of argument
; AX = length of agrgument

	push    cx
	push    di

	mov     bx,0080h

	or      ax,ax
	jz      argv8

	xor     ah,ah

argv1:  mov     cx,-1

argv2:  inc     bx
	cmp     byte ptr es:[bx],0dh
	je      argv7
	cmp     byte ptr es:[bx],20h
	je      argv1
	cmp     byte ptr es:[bx],09h
	je      argv1

	jcxz    argv2

	inc     ah
	cmp     ah,al
	je      argv4
	not     cx
	jmp     short argv2

argv4:  mov     ax,bx

argv5:  inc     bx
	cmp     byte ptr es:[bx],0dh
	je      argv6
	cmp     byte ptr es:[bx],20h
	je      argv6
	cmp     byte ptr es:[bx],09h
	jne     argv5

argv6:  xchg    bx,ax
	sub     ax,bx
	jmp     argvx

argv7:  xor     ax,ax
	jmp     argvx

argv8:  mov     ax,3000h
	int     21h
	cmp     al,3
	jb      argv7
	mov     es,es:[2ch]
	xor     di,di
	xor     al,al
	mov     cx,-1
	cld

argv9:  repne   scasb
	scasb
	jne     argv9
	add     di,2
	mov     bx,di
	mov     cx,-1
	repne   scasb
	not     cx
	dec     cx
	mov     ax,cx

argvx:  pop     di
	pop     cx
	ret

argv    endp

handle  dw      1

row     db      1

flag	db	0	; 0 = Normal operation
			; 1 = TTY mode
			; 2 = Clean mode
			; 3 = Eliminate control codes & high-bit codes
			; 4 = Hex Dump - Clean
			; 5 = Hex Dump - All characters
			; 6 = Strip high bit

pageno	db	0

colno	db	50h

rowno	db	18h

attrib	db	17h

cx_reg	dw	0

signon	db	"File SEE Utility Ver 4 ",4," Amit Y. Gurdasani",0dh,0ah,0ah,"$"

syntax	db	"Syntax: SEE <filename.ext> [/T] [/C] [/H] [/D] [/E] [/S] [/?]",0dh,0ah
	db	"Use /? for this Help message.",0dh,0ah
	db	"Use /T for standard DOS TTY output.",0dh,0ah
	db	"Use /C for Cleaned output.",0dh,0ah
	db	"Use /H for Hexadecimal dump.",0dh,0ah
	db	"Use /D for DEBUG-type Hexadecimal dump.",0dh,0ah
	db	"Use /E for Elimination for high-bit and control codes.",0dh,0ah
	db	"Use /S for Stripping high bit.",0dh,0ah

sy_len	equ	$-syntax

argmsg	db	0dh,0ah,"Error: Invalid switch.",0dh,0ah
ar_len	equ	$-argmsg

opener	db	0dh,0ah,"Error: Cannot open file.",0dh,0ah
op_len	equ	$-opener

reader	db	0dh,0ah,"Error: Cannot read file.",0dh,0ah
rd_len	equ	$-reader

closer	db	0dh,0ah,"Error: Cannot close file.",0dh,0ah
cl_len	equ	$-closer

lowver	db	0dh,0ah,"Needs at least DOS Version 2.X to run.",0dh,0ah,"$"

morer	db	0dh,0ah,"Press any key for more . . .",0dh,"$"

fbuff	db	16 dup (32)

hdg	db	13,10,"          0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F "
	db	6 dup (' ')
	db	"0123456789ABCDEF",0dh,0ah,"$"
obuff	db	"nnnn", 5 dup (32)
obuff1	db	"nn nn nn nn nn nn nn nn nn nn nn nn nn nn nn nn"
	db	7 dup (' ')
obuff_len equ	$-obuff

flen	dw	0

fptr	dw	0

fileptr	equ	$

bufsize	equ	60000

_TEXT	ends

	end	dump1
