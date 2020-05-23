	page	66, 80
	name	MOVE
	title	File move utility

CODE	segment byte public 'CODE'

	assume cs:CODE, ds:CODE, es:CODE, ss:CODE

	org	100h			; To allow for .COM production

	include	USER.INC		; Include user interface module
					; (for ArgGet macro)

move00:	call	argc			; Get number of command-line arguments
	cmp	al, 2			; Are they two in number?
	mov	dx, offset syntax	; If not, set error message
	jb	moveE1			; and abort

					; A potential move has been requested
					; so check validity
	mov	mrout, offset moveR	; Make RapidMove default mode
	call	moveRC			; Validate RapidMove
	jnc	moveR1			; If so, perform RapidMove
	mov	mrout, offset moveB	; Else make BinaryMove default mode
	call	moveBC			; Validate BinaryMove
	jc	moveE1			; if not, terminate with error message

	cmp	al, 3			; Are arguments more than 3?
	ja	moveM			; If so, perform Multiple Move

					; QuickMove
	
	jmp	short move01		; If not, perform QuickMove

moveE1:	jmp	moveE			; Relay to error handler
moveR1:	call	moveR			; Tab to perform RapidMove
	int	20h

moveRC	proc	near			; Tests if RapidMove is usable

	push	ax			; Save general and index registers
	push	bx
	push	cx
	push	dx
	push	si
	push	di

	call	argc
	mov	si, 5ch			; Address default FCBs present in
	mov	di, 6ch			; program PSP to find out the drives
	mov	ah, 19h			; Get default drive (to check against
	int	21h			; if no drive is mentioned)
	inc	ax			; Increase by 1 to compare it with FCBs
	push	ax			; Save current drive value

	cmpsb				; Compare the drives (if any) mentioned
	je	moveRCE			; If same, exit without carry flag set

	dec	si			; Point back to source drive value
	lodsb				; Get it
	sub	ah, ah
	or	al, ah			; Is it default drive
	jz	moveRC1			; If so, go handle it

	dec	di			; Point back to destination drive value
	mov	al, byte ptr es:[di]	; Get it
	sub	ah, ah
	or	al, ah			; Is it default drive?
	jz	moveRC2			; If so, go handle

	pop	ax			; Set stack right
moveRCQ:				; RapidMove not possible
	pop	di			; so return with carry flag set
	pop	si			; and restore registers
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	stc				; Set carry flag
	ret				; exit routine

					; The drives mentioned match
moveRCE: pop	ax			; Set stack right

	mov	ax, 1
	call	argv
	call	
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	clc				; Clear carry flag
	ret				; exit routine
					; Source drive is mentioned only
red2:	pop	ax			; Get default drive
	dec	di			; Address destination drive number
	cmp	al, byte ptr es:[di]	; Is it the same as the default drive?
	je	moveRCE			; If so, signal that RapidMove possible
	jmp	short moveRCQ		; If not, 

					; Destination drive is mentioned only
red3:	pop	ax			; Get default drive
	dec	si			; Address source drive number
	mov	di, si			; using DI
	scasb				; Is it the same as the default drive?
	jne	redq			; If not, abort
	call	word ptr cs:[mrout]	; Go move

redh	proc	near
					; The file is on the same drive
	sub	ax, ax			; Get source path
	mov	bx, ax
	inc	ax
	add	bl, 80h
	push	ax
	push	bx
	call	argv
	mov	si, bx

	pop	bx
	call	argc

redh	endp
	
argc	proc	near

	push	bx
	mov	bx, 80h
	ArgCount
	pop	bx
	ret

argc	endp

argv	proc	near

	mov	bx, 80h
	ArgGet
	ret

argv	endp

mrout	dw	offset moveB

syntax	db	"Usage :-", 13, 10, 10
	db	"QuickMove:", 9, "MOVE source [dest]", 13, 10, 10
	db	"MultiMove:", 9, "MOVE dest source1 source2 [source3 [source4 "
	db	". . . ]]", 13, 10, '$'

CODE	ends

	end	move00
