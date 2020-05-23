	page    66, 80
	name    AutoBack
	title   Automatic file backup

_TEXT   segment byte public 'CODE'

	org     100h

; Equates

cmd     equ     80h                     ; Command line address in PSP
env	equ	2ch			; Environment segment address in PSP

intvect	equ	21h * 4			; Interrupt vector for int 21h

					; Whitespace codes
cr      equ     0Dh                     ; Carriage return ASCII code
lf      equ     0Ah                     ; Line feed ASCII code
space   equ     ' '                     ; Space character
tab     equ     09h                     ; Tab ASCII code

; Initial jump to initialization routine

	assume  cs: _TEXT, ds: _TEXT, es: _TEXT, ss: _TEXT

begin:  jmp     init0

; Data area required for TSR

; Segment and offset of original interrupt routine

oldadd  equ	$		; To call the interrupt routine, we first
oldoff  dw      0		; push the flags register on to the stack
oldseg  dw      0		; and then make a far call to the dword ptr

; Source and destination directories and their lengths

srcdir  db      67 dup (0)
srclen	db	0
destdir db      67 dup (0)
destlen	db	0

tempdir	db      'X'
tcln	db	':'
tbsl	db	'\'
temppath db	64 dup (0)

dtempdir db	0
dtcln	db	0			; colon comes here
dtbsl	db	0			; backslash comes here
dtemppath db	64 dup (0)

; TSR interrupt routines
	
	assume  cs: _TEXT, ds: NOTHING, es: NOTHING, ss: NOTHING

; Interrupt 21h routine

auto0:	push	ax			; Save registers
	push	bx
	push	cx
	push	dx
	push	ds
	push	es
	push	si
	push	di

	cmp	ah, 0fh			; FCB file open?
	je	auto1			; Yes; handle it
	cmp	ah, 16h			; FCB file creation?
	je	auto1			; Yes; handle it
	cmp	ah, 39h			; Directory creation?
	je	autor0			; Yes; handle it
	cmp	ah, 3Ch			; File creation?
	je	autor0			; Yes; handle it
	cmp	ah, 3Dh			; File open?
	je	autor1			; Yes; handle it
	cmp	ah, 5Bh			; New file creation?
	je	autor0			; Yes; handle it
	cmp	ah, 6Ch			; Extended open file?
	je	autor2			; Yes; handle it

	jmp	autoy			; Exit to original routine

autor0:	jmp	auto11			; Relay to file creation handler

autor1:	jmp	auto9			; Relay to file open handler

autor2:	jmp	auto10			; Relay to extended open handler

autor3:	jmp	autox			; Relay to exit point

auto1:	mov	bx, dx
	mov	dl, byte ptr ds:[bx]	; Get drive number
	mov	ah, 47h			; Get current directory
	push	cs
	pop	ds
	assume	ds: _TEXT
	mov	si, offset temppath	; set the buffer
	pushf
	call	dword ptr cs:[oldadd]

	cmp	dl, 0			; is it the default drive?
	jnz	auto2			; No; get drive letter

	mov	ah, 19h			; Get default drive
	pushf
	call	dword ptr cs:[oldadd]
	mov	dl, al

auto2:	add	dl, 'A'			; get drive letter
	mov	tempdir, dl		; store it

	push	cs
	pop	es			; Address TSR data
	assume	es: _TEXT

	mov	si, offset destdir	; Copy the destination path
	mov	di, offset dtempdir	; so we know what file to copy to
	mov	cl, destlen
	mov	ch, 0
	rep	movsb			; Do it
	mov	al, 0			; Store a null character
	stosb

	push	di			; Save path position for later

	mov	si, offset srcdir
	mov	di, offset tempdir	; Address the paths
	mov	cl, srclen

	rep	cmpsb			; Compare the strings
	jne	autor3			; Exit if they're not identical

	mov	si, di			; SI is now the end of base source
	pop	di			; and DI will be end of base destination
	dec	di			; Copy the remainder of the WFP
	mov	cx, 67

auto3:	lodsb				; Copy each character
	stosb				; till we hit
	or	al, al			; a null terminator
	loopnz	auto3			; Then exit, otherwise loop

	dec	di			; Store a backslash
	push	di			; and save the beginning
	dec	si			; of the filename
	push	si			; and the source
	mov	al, '\'
	stosb

	mov	cx, 8			; Now copy the filename of the
	mov	bx, sp			; file to be opened.
	mov	si, ss:[bx + 12]	; Address it.
	inc	si
	mov	ax, ss:[bx + 10]
	mov	ds, ax
	assume	ds: NOTHING
	
auto4:	lodsb				; Get next character
	cmp	al, ' '			; Is it a space?
	je	auto5			; Yes, so stop
	stosb				; Otherwise, copy it
	loop	auto4			; and continue copying.

auto5:	mov	si, ss:[bx + 12]	; Now copy the extension.
	add	si, 9
	cmp	byte ptr ds:[si], ' '	; Is there one?
	je	auto7			; No, so don't bother.
	mov	al, '.'			; otherwise, store a period.
	stosb
	mov	cx, 3			; Copy it.

auto6:	lodsb				; Get next character
	cmp	al, ' '			; Is it a space?
	je	auto7			; Yes, so stop.
	stosb				; Otherwise, store the character
	loop	auto6			; and loop.

auto7:	mov	al, 0			; Store a null terminator.
	stosb

	push	cs			; Address our data
	pop	ds
	assume	ds: _TEXT

	pop	di			; Now copy the filename to the source.
	pop	si
	mov	cx, 14

auto8:	lodsb				; Copy next character
	stosb				; Store it
	cmp	al, 0			; If it was not a null terminator
	loopnz	auto8			; continue to loop

	jmp	copy0			; Copy the file

auto9:	assume	ds: NOTHING, es: NOTHING ; Handler for file creation and open
	mov	bl, al

auto10:	and	bl, 3			; Are we writing to a file?
	jnz	auto11			; If so, continue

	jmp	autoy			; Otherwise, exit

auto11:	mov	si, dx			; Find the length of the pathname
	mov	cx, 67

auto12:	lodsb				; Get next character
	or	al, al			; Is it the null terminator?
	loopnz	auto12			; No; loop

	dec	si			; Calculate path length
	sub	si, dx
	xchg	si, dx
	mov	cx, dx

	push	cs
	pop	es
	assume	es: _TEXT
	mov	di, offset tempdir
	call	ToUpper			; and convert name to uppercase.

	add	di, cx			; Append a null character
	mov	al, 0			; to the file name.
	stosb

	cmp	es:tcln, ':' 		; Is drive letter included?
	jne	auto17			; No, so handle that
	cmp	es:tbsl, '\'		; Is a backslash included?
	je	auto15			; Yes, so continue.

					; A backslash is not included, so we
					; find the current working directory.

	push	cs			; Address our data
	pop	ds
	assume	ds: _TEXT

	mov	si, offset tempdir	; Copy drive letter, colon and backslash
	mov	di, offset dtempdir
	movsw
	mov	al, '\'
	stosb

	mov	ah, 47h			; Get current directory
	mov	dl, 0			; of the default drive
	mov	si, offset dtemppath	; and store it in the right place
	pushf
	call	dword ptr cs:[oldadd]	; Do it

	mov	cx, 64
	mov	si, offset dtemppath	; Find null terminator

auto13:	lodsb				; Get next character
	or	al, al			; Is it a null terminator?
	loopnz	auto13			; No, keep looping

					; We encounter the null terminator
	dec	si			; so we address it.
	mov	di, offset tbsl		; Address the file name
	xchg	si, di
	mov	al, '\'			; Store a backslash
	stosb
	mov	cx, 64			; Copy it.

auto14:	lodsb				; Get next character
	stosb				; Store it
	or	al, al			; Was it a null character?
	loopnz	auto14			; No; keep looping

					; Now the source is in dtempdir.
					; We have to transfer it to tempdir.
	mov	si, offset dtempdir	; Address them
	mov	di, offset tempdir
	mov	cx, 67
	rep	movsb			; and copy them.

auto15:					; Now we need to determine if
					; the file should be archived.
	mov	cl, srclen
	mov	si, offset srcdir
	mov	di, offset tempdir	; Address the data
	rep	cmpsb
					; A mismatch is detected.
	jne	autoy			; Exit now.

					; We need to copy this file.
	push	di			; Sae remainder of WFP for later.

	mov	si, offset destdir	; Copy the destination directory.
	mov	di, offset dtempdir
	mov	cl, destlen
	mov	ch, 0
	rep	movsb

	pop	si			; Address remainder of WFP to be copied

auto16:	lodsb				; Get next character
	stosb				; and store it.
	or	al, al			; Was it a null terminator?
	jz	autor4			; Yes; so copy the file.
	jmp	short auto16		; Otherwise continue to loop.

auto17:					; Add the drive letter
	assume	ds: NOTHING
	push	cs
	pop	ds
	assume	ds: _TEXT
	mov	si, offset tempdir	; Move name forward by two characters
	mov	di, offset tbsl

auto18:	lodsb				; Copy entire name
	stosb
	or	al, al
	jnz	auto18

	mov	ah, 19h			; Save drive letter
	int	21h
	add	al, 'A'
	mov	tempdir, al
	mov	tcln, ':'		; and a colon

	jmp	auto15			; Handle just like the missing backslash

autor4:	jmp	copy0			; Relay to copy mechanism

copy0:	jmp	short autoy

autox:	pop	di

autoy:	pop	di
	pop	si
	pop	es
	assume	es: NOTHING
	pop	ds
	assume	ds: NOTHING
	pop	dx
	pop	cx
	pop	bx
	pop	ax

	jmp	dword ptr cs:[oldadd]

; TSR subroutines

FileSize proc   near

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
	pushf
	push    dx
	mov     ah, 1ah
	mov     dx, offset DTA
	call    dword ptr cs:[oldadd]
	pop     dx
	mov     ax, 4300h
	call    dword ptr cs:[oldadd]
	mov     ah, 4eh
	call    dword ptr cs:[oldadd]
	mov     dx, cs:fsize_2
	mov     ax, cs:fsize_1
	popf

	ret

DTA     db      20 dup (00)
fattr   db      00
ftime   dw      0000
fdate   dw      0000
fsize_1 dw      0000
fsize_2 dw      0000

FileSize endp

ToUpper proc    near                    ; Converts WFPs to uppercase
					; Call with DS:SI = source address
					; ES:DI = destination address
					; CX = WFP length
	
	push    ax                      ; Save registers
	push	si
	push	di
	push	cx

upper0: lodsb                           ; Get character
	cmp     al, 'a'                 ; is it a lowercase letter?
	jl      upper1                  ; if not, skip
	cmp     al, 'z'
	jg      upper1
	and     al, 0dfh                ; make it uppercase

upper1:	stosb                           ; store it
	loop    upper0			; process next character

	pop	cx
	pop	di
	pop	si
	pop     ax                      ; Restore registers
	ret                             ; and return

ToUpper endp

TSRend  equ     $                       ; End of TSR here

; Initialization routine
; This routine installs the TSR in memory.

	assume  cs: _TEXT, ds: _TEXT, es: _TEXT, ss: _TEXT

init0:	mov	ax, 3000h		; Check DOS version
	int	21h
	cmp	al, 2			; Is it lower than 2?
	mov	dx, offset version
	jb	initr0			; Yes, so abort with error

	call    ArgCount                ; How many arguments do we have?
	cmp     ax, 3                   ; Is it two?
	mov	dx, offset syntax
	je      init@0                  ; Yes, so continue

initr0:	jmp	initx			; Relay to abort point

init@0:	mov     ax, 1                   ; Fetch source path name
	call    ArgGet
	mov     si, bx                  ; Copy it in uppercase
	push	si
	mov     di, offset srcdir
	mov     cx, ax
	mov	srclen, al		; Save the length
	call    ToUpper
	pop     si
	mov     di, offset initsrc
	mov     cx, ax
	call    ToUpper

	mov     ax, 2                   ; Fetch destination path name
	call    ArgGet
	mov     si, bx                  ; Copy it in uppercase
	push    si
	mov     di, offset destdir
	mov     cx, ax
	mov	destlen, al		; Save the length
	call    ToUpper
	pop     si
	mov     di, offset initdest
	mov     cx, ax
	call    ToUpper
	
	mov	ax, ds:[env]		; Get address of environment block
	mov	es, ax			; and free it
	mov	ah, 49h
	int	21h

	mov     ax, 3521h               ; Get address of original
	int     21h                     ; DOS interrupt.
	mov     ds:oldseg, es           ; Save the segment and the
	mov     ds:oldoff, bx           ; offset address.

	sub	di, di			; Set the interrupt vector
	mov	es, di
	cli
	mov	es:[intvect], offset auto0
	mov	es:[intvect + 2], cs
	sti

	mov     ah, 9                   ; Display
	mov     dx, offset initmsg      ; banner
	int	21h
	mov     dx, offset initmsg1
	int	21h
	mov     dx, offset initmsg2
	int	21h

	mov     dx, offset TSREnd
	int     27h                     ; Terminate and stay resident


initx:  mov     ah, 9                   ; Display
	int     21h
	
	int     20h                     ; Exit

; Initialization subroutines

ArgCount proc   near

; This procedure returns the number of arguments.
;
; Returns AX = argument number

	push    bx
	push    cx
	mov     bx, cmd
	mov     ax, 1

argc1:  mov     cx, -1

argc2:  inc     bx
	cmp     byte ptr es:[bx], 0dh
	je      argc3
	cmp     byte ptr es:[bx], 20h
	je      argc1
	cmp     byte ptr es:[bx], 09h
	je      argc1

	jcxz    argc2

	inc     ax
	not     cx
	jmp     argc2

argc3:  pop     cx
	pop     bx
	ret

ArgCount endp

ArgGet  proc    near

; This procedure returns the address of a particular argument.
;
; Call with :-
;
; AX = argument number
;
; Returns :-
;
; ES:BX = address of argument
; AX = length of argument

	push    cx
	push    di

	mov     bx, cmd

	or      ax, ax
	jz      argv8

	xor     ah, ah

argv1:  mov     cx, -1

argv2:  inc     bx
	cmp     byte ptr ds:[bx], 0dh
	je      argv7
	cmp     byte ptr ds:[bx], 20h
	je      argv1
	cmp     byte ptr ds:[bx], 09h
	je      argv1

	jcxz    argv2

	inc     ah
	cmp     ah,al
	je      argv4
	not     cx
	jmp     argv2

argv4:  mov     ax, bx

argv5:  inc     bx
	cmp     byte ptr ds:[bx], 0dh
	je      argv6
	cmp     byte ptr ds:[bx], 20h
	je      argv6
	cmp     byte ptr ds:[bx], 09h
	jne     argv5

argv6:  xchg    bx, ax
	sub     ax, bx
	jmp     argvx

argv7:  xor     ax, ax
	jmp     argvx

argv8:  mov     ax, 3000h
	int     21h
	cmp     al, 3
	jb      argv7
	mov     es, ds:[2ch]
	xor     di, di
	xor     al, al
	mov     cx, -1
	cld

argv9:  repne   scasb
	scasb
	jne     argv9
	add     di, 2
	mov     bx, di
	mov     cx, -1
	repne   scasb
	not     cx
	dec     cx
	mov     ax, cx

argvx:  pop     di
	pop     cx
	ret

ArgGet  endp

; Initialization data area

initmsg db      "AUTOBACK ", 4, " by Amit Gurdasani", cr, lf
	db      "Use to automatically copy modified files from a source to a "
	db	"destination path.", cr, lf, lf
	db      "AUTOBACK active.", cr, lf
	db      "Source path is "
initsrc db      67 dup ('$')
initmsg1 db     '.', cr, lf, "Destination path is "
initdest db     67 dup ('$')
initmsg2 db     '.', cr, lf, '$'

version	db	"AUTOBACK requires MS-DOS 2.0 or later to function.", cr, lf
	db	"Besides, it's time you upgraded!", cr, lf, '$'

syntax  db      "AUTOBACK ", 4, " by Amit Gurdasani", cr, lf
	db      "Use to automatically copy modified files from a source to a "
	db	"destination path.", cr, lf, lf
	db      "Usage: AUTOBACK <sourcepath> <destinationpath>", cr, lf, '$'

_TEXT   ends

	end     begin
