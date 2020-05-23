	page	66, 80
	title	KILL: TSR remover
	name	KILL

_TEXT	segment	byte public 'CODE'

	assume cs:_TEXT, ds:NOTHING, es:NOTHING, ss:NOTHING

	include	USER.INC

	org	100h

_kill:	jmp	_itsr1

_stko	dw	0
_stks	dw	0

_ivt	dd	256 dup (0)

_i64ho	dw	0
_i64hs	dw	0

_cstr	db	"KILL by Amit Gurdasani, 1996-97", 0

_cstr_l	equ	$ - _cstr

_i64h1:	push	ax
	push	bx
	push	cx
	push	dx
	push	ds
	assume	ds:NOTHING
	push	es
	assume	es:NOTHING
	push	bp
	push	si
	push	di

	assume	ds:_TEXT
	mov	cx, _cstr_l
	mov	si, offset _cstr
	mov	di, si
	rep	cmpsb
	jne	_i64h3

_i64h2:	mov	bp, sp
	mov	ss:[bp + 6], cs

_i64h3:	pop	di
	pop	si
	pop	bp
	pop	es
	assume	es:NOTHING
	pop	ds
	assume	ds:NOTHING
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	
	cmp	word ptr cs:_i64ho, 0
	je	_i64h5

	jmp	dword ptr cs:_i64ho

_i64h5:	cmp	word ptr cs:_i64hs, 0
	je	_i64h6

	jmp	dword ptr cs:_i64ho

_i64h6:	iret

_tsrp	equ	$

	assume	cs:_TEXT, ds:_TEXT, es:_TEXT, ss:_TEXT

_itsr1:	mov	bx, 80h
	ArgCount		; Ain't reusable code wonderful?
	cmp	ax, 1
	jle	_itsr3

	mov	ax, 3564h
	int	21h
	assume	es:NOTHING
	cmp	bx, offset _i64h1
	je	_itsr1A

	mov	ah, 9
	mov	dx, offset _kabort
	int	21h
	int	20h

_itsr1A: int	64h

	push	es
	pop	ds
	assume	ds:NOTHING
	mov	si, offset _ivt
	sub	di, di
	mov	es, di
	mov	cx, 1024

	cli
	rep	movsb
	sti

	mov	ax, ds
	push	ax

_itsr2A: dec	ax
	mov	es, ax
	inc	ax
	inc	ax
	add	ax, word ptr es:[3]
	mov	cx, cs
	cmp	ax, cx
	je	_itsr2B

	push	ax
	jmp	short _itsr2A

_itsr2B: pop	ax
	mov	es, ax
	push	ax
	mov	ah, 49h
	int	21h
	pop	ax
	mov	cx, ds
	cmp	ax, cx
	je	_itsr2C

	push	ax
	jmp	short _itsr2B

_itsr2C: push	cs
	pop	ds
	assume	ds:_TEXT

	mov	ah, 9
	mov	dx, offset _tsrm
	int	21h
	int	20h

_itsr3:	mov	cx, 1024
	sub	si, si
	mov	ds, si
	assume	ds:NOTHING
	mov	di, offset _ivt
	rep	movsb

	mov	ax, 3564h
	int	21h
	assume	es:NOTHING
	mov	_i64ho, bx
	mov	_i64hs, es

	mov	ax, 2564h
	mov	dx, offset _i64h1
	push	cs
	pop	ds
	int	21h

	mov	ax, word ptr ds:[2ch]
	mov	es, ax
	assume	es:NOTHING
	mov	ah, 49h
	int	21h

	mov	ah, 9
	mov	dx, offset _kloadm
	int	21h

	mov	dx, offset _tsrp
	int	27h

	mov	ax, _i64hs
	mov	es, ax
	assume	es:NOTHING
	mov	ax, 2564h
	mov	bx, _i64ho
	int	21h

	int	20h

_kloadm	db	"KILL: Resident.", 13, 10, "Type KILL A to uninstall TSRs.", 13, 10, '$'
_tsrm	db	"KILL: TSRs uninstalled.", 13, 10, '$'
_kabort	db	"KILL: Not loaded previously.", 13, 10, '$'

_TEXT	ends

	end	_kill
