IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT



; --- INCLUDES -----------------------------------------------------------------
INCLUDE "rand.inc"
INCLUDE "keyb.inc"
INCLUDE "draw.inc"
INCLUDE "core.inc"

SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height

COLS EQU 16
ROWS EQU 4



; -------------------------------------------------------------------
CODESEG

;;;;;;;;;;;;;;;
;;  Drawing  ;;
;;;;;;;;;;;;;;;

PROC drawRow
	ARG @@row: dword
	USES eax, ebx, ecx
	mov ecx, 0   ; column/counter
	@@colLoop:
		mov ax, [esi]
		cmp ax, 0
		je @@next
		mov eax, 20
		mul ecx
		mov ebx, eax
		mov eax, 10
		mul [@@row]
		call drawRectangle, ebx, eax, 18, 9, 180
		@@next:
		add esi, 4
		inc ecx
		cmp ecx, COLS
		jne @@colLoop
	ret
ENDP drawRow


PROC drawlives
	USES eax, ecx, ebx, esi
	mov esi, offset life_map
	mov ecx, 0
	mov bl, [lives]

	@@lifeLoop:
		cmp ecx, ebx;ebx
		je @@end

		mov eax, 20
		mul ecx
		call draw_map, esi, eax, SCRHEIGHT-20, 20, 20
		inc ecx
		jmp @@lifeLoop

	@@end:
	ret
ENDP drawlives

PROC drawBlocks
	USES ecx, eax, ebx, esi, edi
	mov ecx, 0
 	mov esi, offset blocks
	@@rowLoop:
		call drawRow, ecx
		inc ecx
		cmp ecx, ROWS
		jne @@rowLoop
	ret
ENDP drawBlocks


PROC drawPaddle
	USES eax
	mov eax, [paddlePos]
	call drawRectangle, eax, SCRHEIGHT-5, 35, 5, 3
	cmp [bullets], 0
	je @@end
	add eax, 15
	call drawRectangle, eax, SCRHEIGHT-5, 5, 5, 6
	@@end:
	ret
ENDP drawPaddle


PROC drawBall
	USES eax, ebx, edx
	mov ax, [ballX]
	mov bx, [ballY]
	mov edx, 120
	cmp [ball_mode], 0
	je @@draw
	@@p1:
	cmp [ball_mode], 1
	jne @@draw
	mov edx, 40
	jmp @@draw

	@@draw:
	call drawRectangle, eax, ebx, 5, 5, edx
	ret
ENDP drawBall

;;;;;;;;;;;;;;;
;; Animation ;;
;;;;;;;;;;;;;;;

PROC movePaddle
	ARG @@amount:word
	USES ebx, eax
	mov bx, [@@amount]
	mov eax, [paddlePos]

	cmp bx, 0
	jl @@check_move_left

	@@check_move_right:
	cmp ax, SCRWIDTH-35
	jge @@skip
	jmp @@move

	@@check_move_left:
	cmp ax, 0
	jle @@skip

	@@move:
	add [paddlePos], ebx

	@@skip:
	ret
ENDP movePaddle

PROC spawnPowerup
	USES eax, ebx, edx

	mov [powerupY], 1
	mov edx, 0
	call rand
	mov ebx, SCRWIDTH-5
	div ebx
	mov [powerupX], dx

	mov edx, 0
	call rand
	mov ebx, 2
	div ebx
	mov [powerupMode], dx

	ret
ENDP spawnPowerup

PROC drawBullet
	USES eax, ecx, ebx
	cmp [bulletY], 0
	je SHORT @@end

	@@move:
	sub [bulletY], 2
	mov ax, [bulletX]
	mov bx, [bulletY]
	call drawRectangle, eax, ebx, 5, 5, 6

	mov ecx, 0
	cmp ebx, 10*ROWS ;; This is where the zone with the rows begins.
	jge @@end
	call CheckCollisionWithBlock, eax, ebx
	add eax, 5
	call CheckCollisionWithBlock, eax, ebx
	cmp ecx, 1
	jne @@end
	mov [bulletY], 0

	@@end:
	ret
ENDP drawBullet

PROC drawPowerup
	;ARG @@powerup_x:
	USES eax, ebx, ecx, edx, edi, esi
	cmp [powerupY], 0
	je @@end
	@@check_paddle_collision:
	cmp [powerupY], SCRHEIGHT-10  ;; Only check for collision with paddle if powerup is at the same height.
	jl SHORT @@move       ;; Skip paddle collision detection.
	mov eax, [paddlePos]
	cmp ax, [powerupX]
	jge @@boundary_check       ;; paddlePos >= ballX => No collision with paddle
	add eax, 35                 ;; 35 = width of paddle
	cmp ax, [powerupX]
	jge @@powerup_collision              ;; paddlePos >= ballX+35 => Collision with paddle

	@@boundary_check:
	cmp [powerupY], SCRHEIGHT-5
	jge @@bottom_of_screen
	jmp @@move

	@@powerup_collision:
	mov [powerupY], 0
	mov [powerupCounter], 0

	cmp [powerupMode], 0
	jne @@powerup_2
	@@powerup_1:
	mov [penetrating], 300 ;; Duration that powerup remains active.
	mov [ball_mode], 1  ;; 1 = mode for penetrating.
	jmp @@end
	@@powerup_2:
	add [bullets], 3
	jmp @@end

	@@bottom_of_screen:
	mov [powerupY], 0
	mov [powerupCounter], 0
	jmp @@end

	@@move:
	inc [powerupY]
	mov ax, [powerupX]
	mov bx, [powerupY]

	@@draw:
	mov di, [powerupMode]
	add edi, 1

	call drawRectangle, eax, ebx, 5, 5, edi

	@@end:
	ret
ENDP drawPowerup


PROC CheckCollisionWithBlock
	ARG @@x:word, @@y:word RETURNS ecx   ;; Returns 1 if collision in true.
	USES eax, edi, esi, edx, ebx

	mov esi, offset blocks
	mov edx, 0

	mov dx, 0
	mov ax, [@@x]
	mov bx, 20
	div ebx                ; eax has the X index

	mov edi, eax           ; store it in edi for later use.

	mov dx, 0
	mov ax, [@@y]
	mov bx, 10
	div ebx                ; eax has the Y index

	mov ebx, COLS
	mul ebx
	add eax, edi           ; Calculated the 1-dimensional index from a 2D coordinate
	mov ebx, 4             ; * 4 because we take steps of 4 bytes
	mul ebx

	add esi, eax           ; Move offset
	mov ax, [esi]
	cmp ax, 0
	je @@skip              ; If == 0 => No block at current position.
	mov [esi], edx         ; ecx contains 0 => No collision.
	inc [kills]
	mov ecx, 1             ; Put 1 in the return register. 1 => collision
	@@skip:
	ret
ENDP CheckCollisionWithBlock


PROC moveBall
	USES eax, ebx, ecx, edx, edi

	mov ebx, 10*ROWS  ;; This is where the zone with the rows begins.
	cmp bx, [ballY]
	jle @@check_paddle_collision

	@@check_block_collisions:
		mov ax, [ballX]
		mov bx, [ballY]
		mov ecx, 0
		call CheckCollisionWithBlock, eax, ebx
		cmp ecx, 0
		je @@check_paddle_collision
		cmp [penetrating], 0
		jle @@invertY

	@@check_paddle_collision:
		cmp [ballY], SCRHEIGHT-10  ;; Only check for collision with paddle if ball is at the same height.
		jne @@boundary_check       ;; Skip paddle collision detection.
		mov eax, [paddlePos]
		sub eax, 5
		cmp ax, [ballX]
		jge @@boundary_check       ;; paddlePos >= ballX => No collision with paddle
		add eax, 35                ;; 35 = width of paddle
		cmp ax, [ballX]
		jl @@boundary_check

		movzx edi, [ballX]
		add edi, 2
		sub edi, [paddlePos]

		@@check_left_side:
		cmp di, 10
		jg @@check_right_side
		;; Hit left side of paddle.
		cmp [ballDx], 0
		jle @@continue
		neg [ballDx]
		jmp @@continue
		@@check_right_side:
		cmp di, 25
		jl @@continue
		;; Hit right side of paddle.
		cmp [ballDx], 0
		jge @@continue
		neg [ballDx]

		@@continue:
		;; Hit middle of the paddle.
		jmp @@invertY

	@@boundary_check:
		;; Check for collision with borders:
		cmp [ballX], 0
		jl @@invertX
		cmp [ballX], SCRWIDTH-5
		jg @@invertX

		cmp [ballY], 0
		jle @@invertY

		cmp [ballY], SCRHEIGHT-5
		jge @@bottom_of_screen
		jmp @@move

	@@invertX:
		neg [ballDx]
		jmp @@move

	@@invertY:
		neg [ballDy]
		jmp @@move

	@@bottom_of_screen:
		mov al, [lives]
		cmp al, 1
		je @@return_to_menu
		dec ax
		mov [lives], al
		call resetPositions
		jmp @@end

		@@return_to_menu:
		call resetPositions
		call resetBlocks
		mov [lives], 3
	 	mov [menu_open], 1
		jmp @@end

	@@move:
		mov ax, [ballDx]
		mov bx, [ballDy]
		add [ballX], ax
		add [ballY], bx
	@@end:
	ret
ENDP moveBall


PROC resetPositions
	mov [paddlePos], SCRWIDTH/2
	mov [ballX], 10
	mov [ballY], SCRHEIGHT/2
	mov [ballDx], 1
	mov [ballDy], -1
	mov [penetrating], 0
	mov [ball_mode], 0
	mov [powerupCounter], 0
	mov [bullets], 0
	ret
ENDP resetPositions


PROC resetBlocks
	USES esi, ecx, eax
	mov ecx, 0
	mov eax, 1
	mov esi, offset blocks
	@@blockLoop:
		cmp ecx, 64
		je @@done
		mov [esi], eax
		add esi, 4
		inc ecx
		jmp @@blockLoop
	@@done:
	ret
ENDP resetBlocks


PROC handleUserInput
	USES eax, ebx
	mov     al, [__keyb_rawScanCode] ; last pressed key
	cmp     al, 01h

	cmp al, 01
	jne	@@continue
	call exit

	@@continue:
	cmp [menu_open], 1
	je @@menu_keys

	@@n1:
		cmp al, 77	; arrow right
		jne @@n2
		call movePaddle, 2
		jmp @@end

	@@n2:
		cmp al, 75	; arrow left
		jne @@n3
		call movePaddle, -2
		jmp @@end

	@@n3:
	cmp al, 57	; space bar
	jne @@end
	cmp [bullets], 0
	je @@end
	cmp [bulletY], 0
	jne @@end
	mov ebx, [paddlePos]
	add ebx, 15
	mov [bulletX], bx
	mov [bulletY], SCRHEIGHT-10
	dec [bullets]
	jmp @@end

	@@menu_keys:
	@@n4:
	cmp al, 57	; space bar
	jne @@end
	mov [menu_open], 0

	@@end:
	ret
ENDP handleUserInput

;;;;;;;;;;;;;;;
;; Game loop ;;
;;;;;;;;;;;;;;;

PROC updateGameState
	USES eax, ebx

	cmp [menu_open], 1
	je SHORT @@end

	@@check_if_game_finished:
		cmp [kills], 64
		jne @@continue_playing
		call resetPositions
		call resetBlocks
		mov [lives], 3
		mov [kills], 0
		jmp @@end

	@@continue_playing:

	inc [gameLoopCounter]
	inc [powerupCounter]
	dec [penetrating]

	@@update_ball_mode:
	cmp [ball_mode], 0
	je @@powerup_counter

	@@p1:
	cmp [ball_mode], 1
	jne @@powerup_counter
	cmp [penetrating], 0
	jg @@powerup_counter
	mov [ball_mode], 0


	@@powerup_counter: ;; Check if the game should spawn a new powerup.
	mov eax, [powerupCounter]
	cmp eax, 200
	jne @@continue

	call spawnPowerup

	@@continue:
	call moveBall

	@@end:
	ret
ENDP updateGameState

PROC drawAll
	USES eax, edx, esi
	call waitVBlank
	call fillBackground, 0
	cmp [menu_open], 1
	je @@draw_menu

	@@draw_game:
	call drawlives
	call drawPaddle
	call drawBall
	call drawBlocks
	call drawPowerup
	call drawBullet
	jmp @@end

	@@draw_menu:
	call setCursor, 5, 7
	;; Draw the title screen.
	mov ah, 9
	mov edx, offset menuMsg
	int 21h

	@@end:
	ret
ENDP drawAll


PROC main
	sti
	cld
	push ds
	pop	es

  call rand_init

  call setVideoMode, 13h
	call __keyb_installKeyboardHandler

	@@gameLoop:
	call handleUserInput
	call updateGameState
	call drawAll
	jmp @@gameLoop

ENDP main

; -------------------------------------------------------------------
DATASEG
	gameLoopCounter	dd 0
	paddlePos dd SCRWIDTH/2
	menu_open dd 1
	blocks DD 64 DUP(1)
	ballX dw 10
	ballY dw SCRHEIGHT/2
	ballDx dw 1
	ballDy dw -1
	lives db 3

	kills dd 0
	bullets dd 0

	penetrating dw 0

	ball_mode dd 0  ;; 0 = default. Changes depending on active powerup.

	powerupY dw 0
	powerupX dw 0

	bulletY dw 0
	bulletX dw 0

	powerupMode dw 0
	powerupCounter dd 0

	life_map db \
		0,0,0,0,0,4,4,4,0,0,0,0,4,4,4,0,0,0,0,0,\
		0,0,0,0,4,4,4,4,4,0,0,4,4,4,4,4,0,0,0,0,\
		0,0,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,0,0,\
		0,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,0,\
		0,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,0,\
		0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,\
		0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,\
		0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,\
		0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,\
		0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,\
		0,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,0,\
		0,0,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,0,0,\
		0,0,0,0,4,4,4,4,4,4,4,4,4,4,4,4,0,0,0,0,\
		0,0,0,0,0,4,4,4,4,4,4,4,4,4,4,0,0,0,0,0,\
		0,0,0,0,0,0,4,4,4,4,4,4,4,4,0,0,0,0,0,0,\
		0,0,0,0,0,0,0,4,4,4,4,4,4,0,0,0,0,0,0,0,\
		0,0,0,0,0,0,0,0,4,4,4,4,0,0,0,0,0,0,0,0,\
		0,0,0,0,0,0,0,0,0,4,4,0,0,0,0,0,0,0,0,0,\
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,\
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

	menuMsg	db 'Press SPACE to start the game.$'

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main
