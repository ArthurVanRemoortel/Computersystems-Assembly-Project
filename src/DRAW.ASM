;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The basic functions used for drawing ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "draw.inc"

VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height

CODESEG

PROC fillBackground
	ARG 	@@fillcolor:byte
	USES 	eax, ecx, edi
	mov	edi, VMEMADR
	mov al, [@@fillcolor]
	mov ah, al
	mov cx, ax
	shl eax, 16
	mov ax, cx
	mov	ecx, SCRWIDTH*SCRHEIGHT/4
	rep	stosd
	ret
ENDP fillBackground


PROC drawRectangle
	ARG 	@@x0:word, @@y0:word, @@w:word, @@h:word, @@color: byte
	USES 	eax, ecx, edx, edi, ebx ; note: MUL uses edx!

	; Compute the index of the rectangle's top left corner
	movzx eax, [@@y0]
	mov edx, SCRWIDTH
	mul edx
	add	ax, [@@x0]

	; Compute top left corner address
	mov edi, VMEMADR
	add edi, eax

	movzx edx, [@@w]	; store width in edx for later reuse
	mov	al,[@@color]
	xor bx, bx        ; Set 0. Row counter.
	@@vertLoop:
		mov ecx, edx
		rep stosb
		sub edi, edx
		add	edi, SCRWIDTH
		inc bx
		cmp bx, [@@h]
		jl @@vertLoop
	ret
ENDP drawRectangle


PROC draw_map
	ARG @@map: dword, @@x0:word, @@y0:word, @@w:word, @@h:word
	USES 	eax, ecx, edx, edi, ebx, esi

	movzx eax, [@@y0]
	mov edx, SCRWIDTH
	mul edx
	add	ax, [@@x0]
	; Compute top left corner address
	mov edi, VMEMADR
	add edi, eax

	movzx edx, [@@w]	; store width in edx for later reuse
	mov esi, [@@map]

	mov cx, 0 ;; row counter
	@@vertLoop:
		mov bx, 0 ;; col counter
		@@colLoop:
		mov eax, [esi]
		cmp bx, [@@w]
		jge @@next_row
		cmp eax, 0
		;je @@testlabel
		stosb
		w@@testlabel:
		inc esi
		inc bx
		jmp @@colLoop

		@@next_row:
		sub edi, edx
		add	edi, SCRWIDTH
		inc ecx
		cmp cx, [@@h]
		jl @@vertLoop
	@@end:
	ret
ENDP draw_map



END
