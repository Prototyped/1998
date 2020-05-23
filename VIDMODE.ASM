	page	66,80
	name	vidmode
	title	VIDMODE: Video Mode setter.

; Author:	Amit Gurdasani
;
; Date:		30-03-1995
;
; Purpose:	To set different video modes.
;
; Type:		VDU services

nummode	equ	25		; Number of modes

CODE	segment

	assume	cs: CODE, ds: CODE, es: CODE, ss: CODE

	org	0100h

vmode0:	jmp	vmode1

syntax	db	"Usage:	VidMode <Mode>",0dh,0ah
	db	"<Mode>	CO40 =  16 color, 40 col, 25 line A/N ³ except MDA",0dh,0ah
	db	"	BW40 =  16 color, 40 col, 25 line A/N ³ 2 color on composite monitor",0dh,0ah
	db	"	CO80 =  16 color, 80 col, 25 line A/N ³ except MDA",0dh,0ah
	db	"	BW80 =  16 color, 80 col, 25 line A/N ³ 2 color on composite monitor",0dh,0ah
	db	"	MONO =      mono, 80 col, 25 line A/N ³ only MDA, mono EGA & VGA",0dh,0ah
	db	"	CGAL =   4 color, 320 x 200       APA ³ 40 x 25, except MDA",0dh,0ah
	db	"	CGAH =   2 color, 640 x 200       APA ³ 80 x 25, except MDA",0dh,0ah
	db	"	PJR1 =  16 color, 160 x 200       APA ³ 20 x 25, only PCjr",0dh,0ah
	db	"	PJR2 =  16 color, 320 x 200       APA ³ 40 x 25, only PCjr",0dh,0ah
	db	"	PJR3 =   4 color, 640 x 200       APA ³ 80 x 25, only PCjr",0dh,0ah
	db	"	EGAL =  16 color, 320 x 200       APA ³ 40 x 25, EGA, MCGA, VGA",0dh,0ah
	db	"	EGAM =  16 color, 640 x 200       APA ³ 80 x 25, EGA, MCGA, VGA",0dh,0ah
	db	"	EB&W =      mono, 640 x 350       APA ³ 80 x 25, mono EGA & VGA",0dh,0ah
	db	"	EGAH =  16 color, 640 x 350       APA ³ 80 x 25, 4 color on 64K EGA",0dh,0ah
	db	"	VB&W =   2 color, 640 x 480       APA ³ 80 x 30, MCGA, VGA",0dh,0ah
	db	"	VGAH =  16 color, 640 x 480       APA ³ 80 x 30, VGA",0dh,0ah
	db	"	VGAL = 256 color, 320 x 200       APA ³ 40 x 25, MCGA, VGA",0dh,0ah
	db	"Press any key to continue:$"

syntax1	db	0dh,0ah
	db	"	EG12 = 12 line A/N ³ 80 x 12, EGA, MCGA, VGA",0dh,0ah
	db	"	EG14 = 14 line A/N ³ 80 x 14, EGA, MCGA, VGA",0dh,0ah
	db	"	EG25 = 25 line A/N ³ 80 x 25, EGA, MCGA, VGA",0dh,0ah
	db	"	VG28 = 28 line A/N ³ 80 x 28, VGA",0dh,0ah
	db	"	EG35 = 35 line A/N ³ 80 x 35, EGA, MCGA, VGA",0dh,0ah
	db	"	EG43 = 43 line A/N ³ 80 x 43, EGA, MCGA, VGA",0dh,0ah
	db	"	EG50 = 50 line A/N ³ 80 x 50, EGA, MCGA, VGA",0dh,0ah
	db	"	VG60 = 60 line APA ³ 640 x 480, MCGA, VGA",0dh,0ah,"$"

table	db	"BW40",0
	db	"CO40",1
	db	"BW80",2
	db	"CO80",3
	db	"MONO",7
	db	"CGAL",4
	db	"CGAH",6
	db	"PJR1",8
	db	"PJR2",9
	db	"PJR3",10
	db	"EGAL",0dh
	db	"EGAM",0eh
	db	"EB&W",0fh
	db	"EGAH",10h
	db	"VB&W",11h
	db	"VGAH",12h
	db	"VGAL",13h
	db	"EG12",81h
	db	"EG14",82h
	db	"EG25",83h
	db	"VG28",84h
	db	"EG35",85h
	db	"EG43",86h
	db	"EG50",87h
	db	"VG60",88h

flag	db	0	; Bit format:	76543210
			; 		xxx	  not used
			; 		   1	  PCjr
			; 		   0	  not PCjr
			; 		    1	  VGA present
			; 		    0	  VGA not present
			; 		     1	  MCGA present
			; 		     0	  MCGA not present
			; 		      1	  EGA present
			; 		      0   EGA not present
			; 		       1  mono monitor/adaptor
			; 		       0  color monitor/adaptor

PCjr	equ	16
VGA	equ	8
MCGA	equ	4
EGA	equ	2
Mono	equ	1

signon	db	"VidMode Version 1.3: EGA/VGA-aware video mode setter",0dh,0ah
	db	"By Amit Gurdasani, 1994-1995",0dh,0ah,0ah,"$"
nocga	db	"Error: No color adaptor detected.",0dh,0ah,"$"
nopcjr	db	"Error: No PCjr adaptor detected.",0dh,0ah,"$"
nomono	db	"Error: No mono EGA/MCGA/VGA adaptor detected.",0dh,0ah,"$"
noega	db	"Error: No EGA (or better) detected.",0dh,0ah,"$"
mcga	db	"Error: Mode unsupported on MCGA.",0dh,0ah,"$"
novga	db	"Error: No VGA detected.",0dh,0ah,"$"
nomcvga	db	"Error: No MCGA/VGA detected.",0dh,0ah,"$"

vmode1:	mov	ah,9			; Sign-on message
	mov	dx,offset signon
	int	21h
	cld

	cmp	byte ptr ds:[5dh],20h	; Get parameter
	mov	dx,offset syntax
	je	error

vmode2:	sub	bl,bl
	mov	si,offset table
	mov	di,5dh

vmode21: mov	cx,4
	repe	cmpsb
	je	vmode4

	inc	bx
	inc	si
	mov	di,5dh
	cmp	bl,nummode
	je	vmode22

	rep	lodsb
	jmp	vmode21

vmode22: mov	dx,offset syntax	; Error message
error:	jmp	vmode12a

vmode4:	lodsb
	push	ax			; Test for EGA (no MCGA)
	call	egatest
	jc	vmode5

	mov	flag,EGA
	cmp	bh,0
	je	vmode51

	inc	flag
	jmp	vmode51

vmode5:	sub	ax,ax			; Test for color monitor
	mov	ds,ax
	cmp	byte ptr ds:[463h],0d4h
	je	vmode51

	inc	flag

vmode51: push	cs
	pop	ds
	mov	cl,flag
	test	cl,EGA
	jz	vmode61

vmode6:	mov	ax,1a00h		; Test for MCGA/VGA
	int	10h
	cmp	al,0			; MCGA/VGA?
	je	vmode61			; No, skip

	or	flag,VGA
	cmp	bl,7
	jne	vmode60
	or	flag,Mono
	jmp	vmode7

vmode60: cmp	bl,8
	jne	vmode605
	jmp	vmode7

vmode605: or	flag,MCGA		; MCGA found:
	and	flag,-2
	cmp	bl,0bh			; Color monitor?
	je	vmode7			; Yes, skip
	or	flag,Mono		; Monochrome monitor
	jmp	vmode7

vmode61: push	ds			; Test for PCjr
	mov	ax,-1
	mov	ds,ax
	mov	al,byte ptr ds:[0eh]
	pop	ds
	cmp	al,0fdh
	jne	vmode7

	or	flag,PCjr

vmode7:	pop	ax			; Request for graphics adaptor modes?
	mov	ah,0
	cmp	ax,6			; (CGA/PCjr/EGA/MCGA/VGA)
	jg	vmode8

	mov	cl,flag
	test	cl,Mono			; No MDA, change mode
	jz	vmode12

	mov	dx,offset nocga		; Display error message, abort
	jmp	vmode12a

vmode13X: jmp	vmode13			; "Relay"
vmode8:	cmp	ax,7
	jg	vmode9
	mov	cl,flag			; MDA "Mono" mode
	test	cl,Mono
	jnz	vmode12

	mov	dx,offset nomono
	jmp	vmode12a

vmode9:	cmp	ax,10			; PCjr modes (only)
	jg	vmode10

	mov	cl,flag
	test	cl,PCjr
	jnz	vmode12

	mov	dx,offset nopcjr
	jmp	vmode12a

vmode10: cmp	ax,16			; EGA/VGA modes (No MCGA)
	jg	vmode11

	mov	cl,flag
	test	cl,EGA
	jnz	vmode12

	mov	dx,offset noega
	jmp	vmode12a

vmode11: test	al,80h
	jnz	vmode13

	mov	cl,flag			; MCGA/VGA modes (only)
	test	cl,VGA
	jnz	vmode12

	test	cl,MCGA
	jnz	vmode12

	mov	dx,offset nomcvga
	jmp	vmode12a

vmode12: mov	ah,0
	int	10h
	int	20h

vmode12a: mov	ah,9
	int	21h

	cmp	dx,offset syntax
	jne	vmode12b

	mov	ah,0
	int	16h

	mov	ah,9
	mov	dx,offset syntax1
	int	21h

vmode12b: int	20h

vmode13: mov	cl,flag
	test	cl,EGA			; EGA present?
	jnz	vmode14
	test	cl,MCGA			; MCGA present?
	jnz	vmode14
	test	cl,VGA			; VGA present?
	jnz	vmode14

	mov	dx,offset noega
	jmp	vmode12a

vmode14: cld

	cmp	al,81h
	je	ega12X
	cmp	al,82h
	je	ega14X
	cmp	al,83h
	je	ega25X
	cmp	al,84h
	je	vga28X
	cmp	al,85h
	je	ega35X
	cmp	al,86h
	je	ega43X
	cmp	al,87h
	je	ega50

vga60:	mov	dx,offset novga
	mov	cl,flag
	test	cl,8
	jz	_vmode12a

	mov	ax,0012h		; Set 640 x 480 APA mode
	int	10h

	mov	ax,1123h		; Set INT 43h for ROM 8 x 8 font
	mov	bl,0
	mov	dl,60
	int	10h			; Will have (480/8) = 60 lines.
	int	20h

ega12X:	jmp	ega12			; "Relays"
ega14X:	jmp	ega14
ega25X:	jmp	ega25
vga28X:	jmp	vga28
ega35X:	jmp	ega35
ega43X:	jmp	ega43
_vmode12a: jmp	vmode12a

ega50:	mov	ax,1130h		; Will skip over last scan line of each
	mov	bh,3			; char. of 8 x 8 font in 640 x 350 line
	int	10h			; mode to create a 50-line mode

	push	es			; Get table of 8 x 8 font
	pop	ds

	push	cs
	pop	es

	mov	si,bp
	mov	di,offset fontbuf

	mov	bx,100h			; 100h (256) chars.
ega50a:	mov	cx,7			; 7 scan lines
	rep	movsb
	inc	si			; Skip over 8th scan line
	dec	bx
	jnz	ega50a			; Next char.

	mov	bp,offset fontbuf	; Buffer for new font
	sub	dx,dx			; First char. code is 0
	mov	cx,100h			; 256 chars. defined
	mov	bx,0700h		; 7 lines per character, block 0
	mov	ax,1110h		; function 11h/10h, load user font
	int	10h			; do it

	mov	ah,1
	sub	ax,ax
	mov	ds,ax
	push	word ptr ds:[487h]
	or	byte ptr ds:[487h],1

	mov	ah,1
	mov	cx,0600h
	int	10h
	
	pop	word ptr ds:[487h]

	mov	dx,03d4h
	mov	ax,0614h
	out	dx,ax
	int	20h

ega12:	mov	ax,1130h

	mov	cl,flag
	test	cl,4			; MCGA?
	jnz	ega12_0			; Yes, go handle it

	mov	bh,2			; Load ROM 8 x 14 font (EGA, VGA)
	int	10h
	jmp	ega12_1

ega12_0: mov	bh,6			;   or ROM 8 x 16 font (MCGA)
	int	10h

ega12_1: push	es
	pop	ds

	push	cs
	pop	es

	mov	si,bp
	mov	di,offset fontbuf

	mov	cx,0e00h		; 14 * 256 lines (256 chars, 14 lines)

ega12a:	lodsb
	stosb
	stosb

	loop	ega12a

	mov	ax,1110h
	mov	bx,1c00h		; 28 (14 * 2) lines per character.
	mov	cx,100h			; 256 chars.
	sub	dx,dx
	mov	bp,offset fontbuf
	int	10h

	sub	ax,ax
	mov	ds,ax
	push	word ptr ds:[487h]
	or	byte ptr ds:[487h],1

	mov	ah,1
	mov	cx,1619h
	int	10h

	pop	word ptr ds:[487h]

	mov	ax,1b14h
	mov	dx,03b4h
	out	dx,ax
	int	20h

vmode12Y: jmp	vmode12a

ega14:	mov	ax,1130h

	mov	cl,flag
	test	cl,4			; MCGA?
	jnz	ega14_0			; yes, go handle it

	mov	bh,2			; Load ROM 8 x 14 font (EGA, VGA)
	int	10h
	jmp	ega14_1

ega14_0: mov	bh,6			;   or ROM 8 x 16 font (MCGA)
	int	10h

ega14_1: push	es
	pop	ds

	push	cs
	pop	es

	mov	si,bp
	mov	di,offset fontbuf

	mov	cx,100h
ega14_2: push	cx
	mov	cx,14
ega14a:	lodsb
	cmp	cx,1			; Last scan line (14)?
	je	ega14b			; Yes, skip
	stosb				; No, store once
	cmp	cx,2			; Second-last scan line (13)?
	je	ega14b			; Yes, skip
	stosb				; No, store twice

ega14b:	loop	ega14a
	pop	cx
	loop	ega14_2

	mov	ax,1110h
	mov	bx,1900h		; 25 (((14-1)*2)-1) lines per character
	mov	cx,100h			; 256 characters
	sub	dx,dx
	mov	bp,offset fontbuf
	int	10h

	sub	ax,ax
	mov	ds,ax
	push	word ptr ds:[487h]
	or	byte ptr ds:[487h],1

	mov	ah,1
	mov	cx,1619h
	int	10h

	pop	word ptr ds:[487h]

	mov	ax,1b14h
	mov	dx,03b4h
	out	dx,ax
	int	20h

ega25:	mov	ax,1111h	; Get ROM 8 x 14 font (for EGA, VGA)
	mov	bl,0		; Get ROM 8 x 16 font (for MCGA)
	int	10h

	sub	ax,ax
	mov	ds,ax
	push	word ptr ds:[487h]
	or	byte ptr ds:[487h],1

	mov	cx,0b0dh
	mov	ah,1
	int	10h
	pop	word ptr ds:[487h]

	mov	dx,3d4h
	mov	ax,0d14h
	out	dx,ax
	int	20h

vmode12X: jmp	vmode12a		; "Relay"

vga28:	mov	dx,offset novga
	mov	cl,flag
	test	cl,8		; Test for VGA
	jz	vmode12X	; No VGA, abort

	mov	ax,1202h	; Else, set scan lines to 400 (VGA only)
	mov	bl,30h
	int	10h

	mov	ax,1111h	; Load ROM 8 x 14 font
	mov	bl,0
	int	10h

	int	20h		; Exit

ega35:	mov	ax,1130h	; Get ROM 8 x 8 font
	mov	bh,3
	int	10h

	push	es
	pop	ds

	push	cs
	pop	es

	mov	si,bp
	mov	di,offset fontbuf

	mov	bx,100h		; 256 chars
ega35a:	mov	cx,8		; 8 lines
	repz	movsb
	sub	ax,ax
	stosb			; Add 2 more scan lines (making an 8 x 10 font)
	dec	bx
	jnz	ega35a

	mov	ax,1110h
	mov	bx,0a00h	; 10 lines
	mov	cx,100h		; 256 chars
	sub	dx,dx
	mov	bp,offset fontbuf
	int	10h

	sub	ax,ax
	mov	ds,ax
	push	word ptr ds:[487h]
	or	byte ptr ds:[487h],1

	mov	ah,1
	mov	cx,0800h
	int	10h

	pop	word ptr ds:[487h]

	mov	dx,3b4h
	mov	ax,0914h
	out	dx,ax
	int	20h

ega43:	mov	ax,1112h	; Load ROM 8 x 8 font into RAM
	mov	bl,0
	int	10h

	sub	ax,ax
	mov	ds,ax
	push	word ptr ds:[487h]
	or	byte ptr ds:[487h],1
	mov	cx,600h
	mov	ah,1
	int	10h
	pop	word ptr ds:[487h]

	mov	dx,3d4h
	mov	ax,714h
	out	dx,ax
	int	20h

egatest: mov	ah,12h
	mov	bl,10h
	int	10h
	cmp	bl,10h
	jne	return

	stc
return:	ret

fontbuf	equ	$

CODE	ends

	end	vmode0
