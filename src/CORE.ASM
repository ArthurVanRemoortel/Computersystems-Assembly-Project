;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Core functions unrelated to the game logic ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "core.inc"
INCLUDE "keyb.inc"

CODESEG

PROC setCursor
	ARG @@col: byte, @@row: byte
	USES edx, eax
	mov  dl, [@@col]  ; Cursor col
	mov  dh, [@@row]  ; Cursor row
	mov  bh, 0
	mov  ah, 02h
	int  10h
	ret
ENDP setCursor

PROC unsetupVideo
	USES eax
	mov	ax, 03h
	int	10h
	ret
ENDP unsetupVideo

PROC setVideoMode
	ARG @@mode: byte
	USES eax
	mov ah, 00h
	mov al, [@@mode]
	int 10h
ret
ENDP setVideoMode

PROC exit
	USES eax
	call unsetupVideo
	call __keyb_uninstallKeyboardHandler
	mov	eax, 4c00h
	int 21h
	ret
ENDP exit

PROC waitVBlank
	USES eax, edx
	mov dx, 03dah
	@@waitVBlank_wait1:
	in al, dx
	and al, 8
	jnz @@waitVBlank_wait1
	@@waitVBlank_wait2:
	in al, dx
	and al, 8
	jz @@waitVBlank_wait2
	ret
ENDP waitVBlank

END
