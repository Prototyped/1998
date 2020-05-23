	page	66, 80
	name	ACCESS
	title	File Access List-maker

; By Amit Gurdasani

CODE	segment

	org	100h

	INCLUDE	user.inc

	assume	cs:CODE, ds:CODE, es:CODE, ss:CODE

start:	jmp	axs1

; Equates

ebptr	equ	2ch			; location of pointer to environment
					; block segment in PSP
cmd	equ	80h			; command line location

i21hvct	equ	4 * 21h			; address of interrupt 21h vector

jftsize	equ	32h			; address of JFT size

jftptr	equ	34h			; address of pointer to JFT

bufsize	equ	81			; size of buffer (incl. CR/LF)

bsize	equ	79			; size of buffer (excl. CR/LF)

sftlen	equ	59			; length of SFT entry

skip	equ	38			; no. of bytes to skip

i21hoa	equ	i21hvct			; address of int 21h vector offset

i21hos	equ	i21hoa+2		; address of int 21h vector segment

INSTALLER equ	0			; states of TSR
ISR	equ	-1
OPENONLY equ	7Fh

; TSR start-up data

fname	db	"C:\ACCESS.LST"		; ACCESS file name
	db	54 dup (0)

i21hptr	equ	$			; Pointer to address of previous int 21h

i21hoff	dw	0			; Offset address of previous int 21h
i21hseg	dw	0			; Segment address of previous int 21h

sftoff	dw	0			; Offset address of first SFT
sftseg	dw	0			; Segment address of first SFT

; TSR variables

handle	dw	0			; file handle

buffer	equ	$			; write buffer

progname db	9 dup (32)		; program name

accode	db	15 dup (32)		; access code

filename db	55 dup (32)		; file filename

crlf	db	13, 10			; CR/LF

axsflag	db	INSTALLER		; State of TSR

; TSR constant data

access	equ	$			; Table of file access codes

	db	15,  8, "FCB Open"
	db	16,  9, "FCB Close"
	db	19, 10, "FCB Delete"
	db	20, 12, "FCB Seq Read"
	db	21, 13, "FCB Seq Write"
	db	22, 10, "FCB Create"
	db	23, 10, "FCB Rename"
	db	33, 12, "FCB Rnd Read"
	db	34, 13, "FCB Rnd Write"
	db	39, 14, "FCB Rnd Blk Rd"
	db	40, 14, "FCB Rnd Blk Wr"
	db	57, 10, "Create Dir"
	db	58, 10, "Delete Dir"
	db	59, 10, "Change Dir"
	db	60,  6, "Create"
	db	61,  4, "Open"
	db	62,  5, "Close"
	db	63,  4, "Read"
	db	64,  5, "Write"
	db	65,  6, "Delete"
	db	86,  6, "Rename"
	db	90, 11, "Create Temp"
	db	91, 10, "Create New"
	db	108, 8, "Ext Open"

; TSR interrupt routines

i21h:	assume	ds:NOTHING, es:NOTHING, ss:NOTHING

	sti
	push	ax			; Save registers
	push	bx
	push	cx
	push	dx
	push	ds
	push	es
	push	si
	push	di
	push	bp

	push	si			; Save SI register
	push	dx			; Save DX register
	push	ds			; Save DS register
	push	cs
	pop	ds			; Address TSR data using DS
	push	es			; Save ES register
	push	cs
	pop	es			; Address TSR data using ES
	assume	ds:CODE, es:CODE

	mov	cx, 24			; Set CX to search for access code
	mov	si, offset access	; Set SI to the address of the table
	xchg	al, ah			; Exchange values of AL and AH
	push	ax			; Save AX register

i21h1:	mov	di, si			; Make DI equal to SI
	inc	si			; Make SI par with DI
	scasb				; Is value pointed to by ES:DI = AL?
	je	i21h2			; If so, move on

	lodsb				; If not, load AL with string length
	mov	ah, 0			; Zero off AH
	add	si, ax			; Increase SI by string length to
	pop	ax			; advance it to the next table entry
	push	ax			; Recall AX
	loop	i21h1			; Loop back

	pop	ax			; If match not found, recall AX
	pop	es			; Recall ES
	pop	ds			; Recall DS
	pop	dx			; Recall DX
	pop	si			; Recall SI
	assume	ds:NOTHING, es:NOTHING
	jmp	i21hx			; Quit TSR routine and jump back to
					; previous int 21h
i21h2:	assume	ds:CODE, es:CODE
	mov	di, offset buffer	; Match is found
	mov	cx, bsize		; Erase write buffer by filling it with
	mov	al, ' '			; spaces
	rep	stosb
	mov	ax, 0A0Dh
	stosw				; put a CR/LF pair in the end

	pop	ax
	push	ax			; Recall AX
	xchg	ah, al			; Set AX right again

	lodsb				; Read length of access code string
	mov	di, offset accode	; Set address of buffer
	mov	cl, al			; Set CX for string length
	sub	ch, ch
	rep	movsb			; Copy string into buffer

	pop	ax			; Recall AX
	pop	es			; Recall ES
	pop	ds			; Recall DS
	assume	ds:NOTHING, es:NOTHING
	cmp	al, 40			; Is function an FCB function?
	jbe	i21h5			; If so, go handle FCB function

	cmp	al, 62			; Is filename a given ASCIIZ string?
	jb	i21h3			; If so, go handle the ASCIIZ string

	cmp	al, 65			; Is function a handle function?
	jb	i21h9			; If so, go handle the handle function

	cmp	al, 108			; Is function an Extended Open?
	je	i21h3_1			; If so, go handle Extended Open

					; All others are routed to ASCIIZ
i21h3:	pop	dx			; Get back values of DX and SI
	pop	si			; saved earlier
	mov	si, dx			; Load SI with the ASCIIZ string address
	jmp	short i21h3_2		; Go on

i21h3_1: pop	dx			; Extended Open is a special case of
	pop	si			; ASCIIZ string. Recall DX and SI.

i21h3_2: mov	di, offset filename	; Load DI with buffer address
	push	es			; Save ES register
	push	cs
	pop	es			; Address TSR data
	assume	es:CODE

i21h4:	lodsb				; Get first character of file name
	cmp	al, 0			; Is it the end?
	je	i21h4_1			; If so, move on
	stosb				; If not, copy it to buffer
	jmp	short i21h4		; Loop back again

i21h4_1: jmp	i21h10			; Go to get program name

					; FCB handler
i21h5:	pop	dx			; Get back values of DX and SI saved
	pop	si			; earlier
	push	es			; Save ES register
	push	cs
	pop	es			; Address TSR data
	assume	es:CODE
	mov	si, dx			; Load SI with address of FCB
	mov	di, offset filename	; Point DI to buffer position
	sub	cx, cx			; Zero out CX register

i21h5_1: lodsb				; Get drive number
	cmp	al, 0			; Is it the default drive?
	je	i21h6			; If so, move on

	add	al, 'A' - 1		; If not, convert it into a drive letter
	stosb				; Store it in the write buffer
	mov	al, ':'			; Store a colon
	stosb

i21h6:	lodsb				; Get first character of file name
	cmp	al, ' '			; Is it a space?
	je	i21h7			; If so, move on
	cmp	cx, 8			; Is it the end of the first part?
	je	i21h7			; If so, move on
	stosb				; If not, save it to buffer
	inc	cx			; Increase CX register (counter)
	jmp	short i21h6		; Loop back

i21h7:	mov	al, '.'			; Store a single period in the buffer
	stosb
	sub	cx, cx			; Zero out CX register
	mov	si, dx			; Point SI to the beginning of the FCB
	add	si, 9			; Point SI to the extension (if any)

i21h8:	lodsb				; Load first letter of extension
	cmp	al, ' '			; Is it a space?
	je	i21h4_1			; If so, go get program name
	cmp	cx, 3			; Is it the end?
	je	i21h4_1			; If so, go get program name
	stosb				; If not, store it in buffer
	inc	cx			; Increase CX register (counter)
	jmp	short i21h8		; Loop back

					; Handle function handler
i21h9:	pop	dx			; Get back values of DX and SI registers
	pop	si			; saved earlier
	push	es			; Save value of ES register
	push	ds			; Save value of DS register
	push	cs
	pop	es			; Address TSR data through ES
	assume	es:CODE

	push	bx			; Save handle
	mov	ah, 51h			; Get address of caller's PSP
	call	i21hc			; Do it
	mov	ds, bx			; Address caller's PSP through DS
	assume	ds:NOTHING
	pop	bx			; Get back handle
	mov	si, word ptr ds:[jftptr] ; Address caller's JFT through DS:SI
	push	word ptr ds:[bx + si]	; Save SFT index (from JFT)
	mov	bx, sftseg		; Address SFT from DS:BX
	mov	ds, bx
	mov	bx, sftoff
	pop	cx			; Get back SFT index
	cmp	axsflag, OPENONLY	; Is Open Only mode chosen?
	je	i21h9_1_5		; If so, go to previous int 21h
	cmp	cl, 4			; Is SFT index among first SFT node?
	ja	i21h9_1			; If not, address next SFT node
	cmp	cl, 3			; Is SFT index for standard streams?
	jb	i21h9_1_5		; If so, go to previous int 21h
	jmp	short i21h9_2		; If not, move on

i21h9_1: lds	bx, ds:[bx]		; Load address of next SFT node in DS:BX
	cmp	cl, 0FFh		; Is the SFT entry -1?
	je	i21h9_1_5		; if so, go to previous int 21h
	jmp	short i21h9_2		; If not, move on

i21h9_1_5: pop	ds			; Recall values of DS and BX registers
	pop	es
	assume	ds:NOTHING, es:NOTHING
	jmp	i21hx			; Go to previous int 21h

i21h9_2: assume	ds:NOTHING, es:CODE
	add	bx, skip		; Skip to filename of first SFT entry
	mov	ax, sftlen		; Find address of filename of required
	mul	cl			; SFT entry in SI
	add	bx, ax
	mov	si, bx
	mov	di, offset filename	; Point DI to write buffer
	sub	cx, cx			; Zero out CX (count) register
	push	si			; Save address of filename

i21h9_3: lodsb				; Read a letter
	cmp	al, ' '			; Is it a space?
	je	i21h9_4			; If so, move on
	cmp	cx, 8			; Is it the end of the first part?
	je	i21h9_4			; If so, move on
	stosb				; If not, save it in buffer
	inc	cx			; Increase CX (count) register
	jmp	short i21h9_3		; Loop back

i21h9_4: mov	al, '.'			; Store a period in the buffer
	stosb
	sub	cx, cx			; Zero out CX (count) register
	pop	si			; Recall value of SI register
	add	si, 8			; Address extension

i21h9_5: lodsb				; Read a letter
	cmp	al, ' '			; Is it a space?
	je	i21h9_6			; If so, go get program name
	cmp	cx, 3			; Is it end of extension?
	je	i21h9_6			; If so, go get program name
	stosb				; If not, store letter in buffer
	inc	cx			; Increase CX (counter) register
	jmp	short i21h9_5		; Loop back

i21h9_6: pop	ds			; Recall value of DS register
	assume	ds:NOTHING, es:CODE

i21h10:	mov	ah, 51h			; Get caller's PSP address
	call	i21hc
	dec	bx			; Decrement it by 1 to get arena header
	push	ds			; Save DS
	mov	ds, bx			; Address arena header through DS
	assume	ds:NOTHING
	mov	si, 8			; Address program name through DS:SI
	mov	di, offset progname	; Point ES:DI to buffer
	mov	cl, 8			; Set CL to 8 (maximum length)

i21h11:	lodsb				; Get a character
	cmp	al, 0			; Is it a null?
	jz	i21h12			; If so, move on
	cmp	cl, 0			; Is 8th character done?
	jz	i21h12			; If so, move on
	dec	cx			; If not, decrement CX (counter)
	stosb				; Store letter in buffer
	jmp	short i21h11		; Loop back

i21h12:	push	cs			; Address TSR data through DS
	pop	ds
	assume	ds:CODE			

	mov	dx, offset buffer
	mov	cx, bufsize
	call	axsf
	pop	ds
	pop	es
	assume	ds:NOTHING, es:NOTHING

i21hx:	pop	bp			; Restore registers
	pop	di
	pop	si
	pop	es
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	jmp	dword ptr cs:i21hptr	; Go to original int 21h routine

; TSR auxiliary routines

i21hc:	pushf
	call	dword ptr cs:i21hptr	; Call original int 21h routine
	ret

axsf:	push	dx
	push	cx

	mov	si, offset fname	; Open ACCESS file
	mov	ax, 6c00h
	mov	bx, 1
	sub	cx, cx
	mov	dx,0000000000010001b
	call	i21hc
	pushf

	cmp	axsflag, INSTALLER	; Is caller installer?
	jne	axsf2			; If not, move on

	popf				; If so, test for error
	mov	dx, offset filerr
	jc	axsfx
	pushf

axsf2:	popf
	mov	handle, ax		; move file pointer to end of file
	mov	bx, ax
	mov	ax, 4202h
	sub	cx, cx
	sub	dx, dx
	call	i21hc
	mov	dx, offset filerr
	pushf

	cmp	axsflag, INSTALLER	; Is caller installer?
	jne	axsf3			; If not, move on

	popf				; If so, test for error
	mov	dx, offset filerr
	jc	axsfx
	pushf

axsf3:	popf
	mov	ah, 40h			; write header to file
	mov	bx, handle
	pop	cx
	pop	dx
	call	i21hc
	mov	dx, offset filerr
	pushf

	cmp	axsflag, INSTALLER	; Is caller installer?
	jne	axsf4			; If not, move on

	popf				; If so, test for error
	mov	dx, offset filerr
	jc	axsfx
	pushf

axsf4:	popf
	mov	ah, 3eh			; close file
	mov	bx, handle
	call	i21hc
	pushf

	cmp	axsflag, INSTALLER	; Is caller installer?
	jne	axsf5			; If not, move on

	popf				; If so, test for error
	mov	dx, offset filerr
	jc	axsfx
	pushf

axsf5:	popf
	ret

axsfx:	pop	dx
	jmp	axsab

endpt	equ	$			; TSR endpoint

; TSR installer data (non-resident)

vermsg	db	"Requires at least DOS version 5.00.", 13, 10, "$"

tsrerr	db	"Unable to install ACCESS.", 13, 10, "$"

filerr	db	"Unable to open/read/close file.", 13, 10, "$"

sign_on	db	"ACCESS: File access logging TSR.", 13, 10
	db	"Installing . . .", 13, 10, 10, "$"

header	db	13, 10
	db	"Program  Operation      File", 13, 10
	db	79 dup ('-'), 13, 10, 10

hd_len	equ	$ - header

; TSR installation routine

axs1:	assume	ds:CODE, es:CODE, ss:CODE
	mov	ah, 9
	mov	dx, offset sign_on
	int	21h			; display sign-on message

	mov	ax, 3306h		; check for ACTUAL DOS version
	sub	bx, bx			; (not to be tricked by SETVER)
	int	21h
	mov	dx, offset vermsg
	cmp	bx, 0
	jz	axs2
	jmp	short axs3

axs2:	jmp	axsab

; Save space by getting rid of environment block.

axs3:	mov	ax, word ptr ds:[ebptr]	; Segment address of environment block
	mov	es, ax			; from offset 2Ch of PSP
	assume	es:NOTHING

	mov	ah, 49h			; Release memory
	int	21h

; Get TSR constants

	sub	ax, ax
	mov	es, ax

	mov	ax, word ptr es:[i21hvct] ; get address of original interrupt
	mov	i21hoff, ax
	mov	ax, word ptr es:[i21hvct+2]
	mov	i21hseg, ax

	mov	ah, 52h			; Load address of DOS List of Lists
	int	21h			; in ES:BX
	add	bx, 4			; Get SFT entry address
	les	bx, es:[bx]

	mov	sftseg, es
	mov	sftoff, bx		; get SFT address

; Handle ACCESS file name and switches

	push	cs
	pop	es			; Address TSR data through ES
	assume	es:CODE
	mov	bx, cmd
	call	argc			; get no. of arguments (macro)
	cmp	ax, 2			; ACCESS filespec given?
	jb	axs5			; no, continue with default

axs3_1:	push	ax
	mov	ax, 1
	call	argv			; get ACCESS file name
	mov	si, bx			; move filename to fname buffer
	mov	di, offset fname
	mov	cx, ax
	rep	movsb

	pop	ax
	cmp	ax, 2			; Are there any switches?
	ja	axs4			; Yes, go handle
	jmp	short axs5

axs4:	mov	ax, 2
	call	argv
	inc	bx
	mov	al, ds:[bx]
	and	al, 0DFh
	cmp	al, 'N'
	je	axs4_1
	cmp	al, 'O'
	je	axs4_2
	jmp	short axs5

axs4_1:	mov	dx, offset header
	mov	cx, hd_len
	call	axsf
	int	20h

axs4_2:	mov	dx, offset header
	mov	cx, hd_len
	call	axsf

	mov	axsflag, OPENONLY
	jmp	short axs5_1

; Write header to ACCESS file

axs5:	mov	dx, offset header
	mov	cx, hd_len
	call	axsf			; Write header to file

; Switch interrupt vectors

axs5_1:	sub	ax, ax
	mov	es, ax			; address Interrupt Vector Table (IVT)

	cli
	mov	word ptr es:[i21hoa], offset i21h
	mov	word ptr es:[i21hos], cs ; set int 21h vectors
	sti

; Terminate and stay resident

	push	cs
	pop	es
	assume	es:CODE

	cmp	axsflag, INSTALLER
	jne	axs6

	mov	axsflag, ISR		; Set TSR state

axs6:	mov	dx, offset endpt
	int	27h			; Terminate and stay resident

; Display error message if unsuccessful

	mov	dx, offset tsrerr
	push	ax

axsab:	mov	ah, 9
	int	21h
	pop	ax
	int	20h

; TSR install subroutines (non-resident)

argc	proc	near

	ArgCount				; Macro
	ret

argc	endp

argv	proc	near

	ArgGet
	ret

argv	endp

	CODE	ends

	end	start
