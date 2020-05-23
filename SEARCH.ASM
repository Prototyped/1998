	page	66, 80
	name	SEARCH
	title	SEARCH - To search text files for strings

_TEXT	segment byte public 'CODE'

	org	100h

	assume	CS:_TEXT, DS:_DATA, ES:_DATA, SS:_STACK

begin:	jmp	see

sign	db	"Search: File search utility", 0dh, 0ah
	db	"by Amit Gurdasani, 1997", 0dh, 0ah, "$", 26

see:	mov	ax, _DATA
	mov	ds, ax
	mov	es, ax
	mov	ax, _STACK
	mov	ss, ax
	mov	base, bp
	mov	bp, sp

	call	look

	mov	bp, base
	mov	ax, 4c00h
	int	21h

INCLUDE	USER.INC

search	proc	near

; To look for a particular string in a buffer and to return the position
; of the string.

; Returns:

; CF set if string not found; if found, CF is clear.
; Offset = String location in buffer if string is found.

	mov	cx, bufsize

srch1:	push	ax
	call	fread			; Get byte
	pop	ax
	cmp	byte ptr ds:[si], al	; Compare it
	je	srch2			; Jump if equal

	jmp	short srch1		; Go loop back

srch2:	mov	dx, strlen		; Get string length
	dec	dx			; Decrement string counter

srch3:	call	fread			; Get next byte
	cmp	byte ptr ds:[si], al	; Compare it
	je	srch3			; Loop if equal
	cmp	dx, -1			; End of string?
	je	srchx			; Exit if so

	push	dx
	pop	dx			; Get string length
	jmp	short srch1		; Search for match

srchx:	pop	dx			; Get string length
	sub	buffpos, dx		; Point to beginning of found match
	call	offsub
	ret				; Return to caller

search	endp

offsub	proc	near

	sub	ds:offsl, dx		; Adjust lower word
	jc	offsub1
	ret

offsub1: dec	ds:offsh		; Adjust higher word
	ret

offsub	endp

offadd	proc	near

	add	ds:offsl, dx		; Adjust lower word
	jc	offadd1
	ret

offadd1: inc	ds:offsh		; Adjust higher word
	ret

offadd	endp

fread	proc	near

fread1:	inc	word ptr ds:buffpos
	cmp	word ptr ds:buffpos, word ptr ds:bufsize
	je	fread2

	push	dx
	mov	dx, 1
	call	offadd
	pop	dx

	mov	si, ds:buffpos
	add	si, buffptr
	lodsb
	ret

fread2:	mov	word ptr ds:buffpos, 0
	sub	word ptr ds:offs, word ptr ds:strlen

	push	ax
	push	bx
	push	cx
	push	dx
	mov	ax, 4200h
	mov	bx, ds:handle
	mov	cx, ds:offsh
	mov	dx, ds:offsl
	int	21h

	mov	ah, 3fh
	mov	bx, ds:handle
	mov	cx, ds:bufsize
	mov	dx, ds:buffptr
	int	21h

	mov	ds:bufsize, ax
	cmp	ax, 0
	jnz	fread3

fread2:	add	sp, +14
	mov	dx, offset eof
	jmp	looka

fread3:	jc	fread2
	mov	si, ds:buffptr
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

fread	endp

look	proc	near	; Main routine

looka:

look	endp

_TEXT	ends

_DATA	segment byte public 'DATA'

; Data and variables:

lcount	dd	?

strlen	dw	?

offs	struc

offsl	dw	?
offsh	dw	?

offs	ends

display	struc

dispoff	db	"XXXXXXXXh  "
displn	db	"00000000  $"

display	ends

heading	db	"Offset     Line no.   String", 0dh, 0ah, 0ah, "$"

eof	db	0dh, 0ah, "--- End of file ---", 0dh, 0ah, "$"

bufsize	dw	40000

match	struc

match1	dw	?
match2	dw	?

match	ends

handle	dw	3

buffpos	dw	0

buffptr	equ	$

_DATA	ends

_STACK	segment public stack 'STACK'

	db	64 dup (197)

_STACK	ends

	end	start
