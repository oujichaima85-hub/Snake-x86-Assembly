; ============================================================
;  snake_full.asm - Snake 8086
;  Assembleur : NASM
;  Execution  : DOSBox  (snake_full.com)
;  Commande   : nasm -f bin snake_full.asm -o snake_full.com
; ============================================================

org 100h
bits 16

jmp start

; ============================================================
;  DONNEES
; ============================================================
snake_x:  times 128 db 0
snake_y:  times 128 db 0
length:   db 4
dir:      db 1           ; 1=droite 2=gauche 3=haut 4=bas
food_x:   db 0
food_y:   db 0
score:    dw 0
rnd_seed: dw 5678h

msg_start: db 'SNAKE 8086 - Appuyez sur une fleche pour commencer !', 13, 10, '$'
msg_over:  db 13, 10, '  GAME OVER !   Score = $'
msg_again: db 13, 10, '  R = Rejouer       ESC = Quitter$'
score_buf: db '00000$'

; Terrain en blocs 4x4 pixels
; Zone jouable : blocs 0..59 (X) et 0..43 (Y)
BSIZE  equ 4    ; taille d'un bloc en pixels
OFS_X  equ 8    ; pixel X du bord gauche
OFS_Y  equ 16   ; pixel Y du bord haut
MAX_X  equ 59   ; index max en X
MAX_Y  equ 43   ; index max en Y

; Couleurs palette mode 13h
C_BG     equ 0
C_BODY   equ 10
C_HEAD   equ 14
C_FOOD   equ 12
C_BORDER equ 15
C_HUD    equ 1

; ============================================================
;  POINT D'ENTREE
; ============================================================
start:
    call init_vars

    ; Ecran de demarrage (mode texte)
    mov ax, 0003h
    int 10h
    mov ah, 02h
    xor bh, bh
    mov dh, 12
    mov dl, 4
    int 10h
    mov ah, 09h
    mov dx, msg_start
    int 21h

wait_key:
    mov ah, 00h
    int 16h
    cmp al, 1Bh
    je  exit_prog
    cmp ah, 48h
    je  wk_up
    cmp ah, 50h
    je  wk_down
    cmp ah, 4Bh
    je  wk_left
    cmp ah, 4Dh
    je  wk_right
    jmp wait_key

wk_up:    mov byte [dir], 3  ;  haut
    jmp start_game
wk_down:  mov byte [dir], 4  ;  bas
    jmp start_game
wk_left:  mov byte [dir], 2  ;  gauche
    jmp start_game
wk_right: mov byte [dir], 1  ;  droite

start_game:
    mov ax, 0013h
    int 10h
    call draw_terrain

; ============================================================
;  BOUCLE PRINCIPALE
; ============================================================
main_loop:
    call read_input
    call update_snake
    call draw_frame
    call wait_delay
    jmp  main_loop

; ============================================================
;  INITIALISATION
; ============================================================
init_vars:
    mov byte [snake_x+0], 15
    mov byte [snake_x+1], 14
    mov byte [snake_x+2], 13
    mov byte [snake_x+3], 12
    mov byte [snake_y+0], 10
    mov byte [snake_y+1], 10
    mov byte [snake_y+2], 10
    mov byte [snake_y+3], 10
    mov byte [length], 4
    mov byte [dir], 1
    mov word [score], 0
    call place_food
    ret

; ============================================================
;  CLAVIER
; ============================================================
read_input:
    mov ah, 01h
    int 16h
    jz  ri_done
    mov ah, 00h
    int 16h
    cmp al, 1Bh
    je  exit_prog
    cmp ah, 4Dh
    je  ri_right
    cmp ah, 4Bh
    je  ri_left
    cmp ah, 48h
    je  ri_up
    cmp ah, 50h
    je  ri_down
    ret
ri_right:
    cmp byte [dir], 2
    je  ri_done
    mov byte [dir], 1
    ret
ri_left:
    cmp byte [dir], 1
    je  ri_done
    mov byte [dir], 2
    ret
ri_up:
    cmp byte [dir], 4
    je  ri_done
    mov byte [dir], 3
    ret
ri_down:
    cmp byte [dir], 3
    je  ri_done
    mov byte [dir], 4
    ret
ri_done:
    ret

exit_prog:
    mov ax, 4C00h
    int 21h

; ============================================================
;  MISE A JOUR DU SERPENT
; ============================================================
update_snake:
    ; Decaler le corps
    mov cl, byte [length]
    xor ch, ch
    dec cx
    jz  us_head
    mov si, cx
us_shift:
    mov di, si
    dec di
    mov al, [snake_x + di]
    mov [snake_x + si], al
    mov al, [snake_y + di]
    mov [snake_y + si], al
    dec si
    jnz us_shift

us_head:
    mov al, byte [dir]
    cmp al, 1
    je  us_r
    cmp al, 2
    je  us_l
    cmp al, 3
    je  us_u
    inc byte [snake_y]
    jmp us_check
us_r: inc byte [snake_x]
    jmp us_check
us_l: dec byte [snake_x]
    jmp us_check
us_u: dec byte [snake_y]

us_check:
    ; Collision murs
    mov al, byte [snake_x]
    cmp al, 0
    jb  game_over
    cmp al, MAX_X
    ja  game_over
    mov al, byte [snake_y]
    cmp al, 0
    jb  game_over
    cmp al, MAX_Y
    ja  game_over

    ; Collision soi-meme
    mov cl, byte [length]
    xor ch, ch
    dec cx
    jz  us_food
    mov si, 1
us_self:
    mov al, byte [snake_x]
    cmp al, [snake_x + si]
    jne us_snx
    mov al, byte [snake_y]
    cmp al, [snake_y + si]
    je  game_over
us_snx:
    inc si
    loop us_self

    ; Manger nourriture
us_food:
    mov al, byte [snake_x]
    cmp al, byte [food_x]
    jne us_done
    mov al, byte [snake_y]
    cmp al, byte [food_y]
    jne us_done
    mov al, byte [length]
    cmp al, 127
    jae us_done
    inc byte [length]
    add word [score], 10
    call place_food
us_done:
    ret

; ============================================================
;  DESSIN COMPLET DE LA FRAME
; ============================================================
draw_frame:
    mov ax, 0A000h
    mov es, ax

    ; Effacer zone de jeu
    mov di, OFS_Y * 320 + OFS_X
    mov dx, OFS_Y
df_clear:
    push dx
    push di
    mov cx, (MAX_X + 1) * BSIZE
    xor al, al
    rep stosb
    pop di
    pop dx
    add di, 320
    inc dx
    cmp dx, OFS_Y + (MAX_Y + 1) * BSIZE
    jl  df_clear

    ; Nourriture
    call draw_food_blk

    ; Serpent
    mov cl, byte [length]
    xor ch, ch
    xor si, si

df_snake:
    ; pixel_x = snake_x[si]*4 + OFS_X
    xor ah, ah
    mov al, byte [snake_x + si]
    mov bx, BSIZE
    mul bx
    add ax, OFS_X
    mov bx, ax          ; BX = pixel_x

    xor ah, ah
    mov al, byte [snake_y + si]
    push bx
    mov bx, BSIZE
    mul bx
    add ax, OFS_Y       ; AX = pixel_y
    pop bx

    ; offset = pixel_y * 320 + pixel_x
    push bx
    push cx
    mov cx, 320
    mul cx              ; AX = pixel_y * 320
    pop cx
    pop bx
    add ax, bx
    mov di, ax

    cmp si, 0
    je  df_head
    mov al, C_BODY
    jmp df_block
df_head:
    mov al, C_HEAD

df_block:
    ; Dessiner un bloc 4x4
    mov byte [es:di],   al
    mov byte [es:di+1], al
    mov byte [es:di+2], al
    mov byte [es:di+3], al
    add di, 320
    mov byte [es:di],   al
    mov byte [es:di+1], al
    mov byte [es:di+2], al
    mov byte [es:di+3], al
    add di, 320
    mov byte [es:di],   al
    mov byte [es:di+1], al
    mov byte [es:di+2], al
    mov byte [es:di+3], al
    add di, 320
    mov byte [es:di],   al
    mov byte [es:di+1], al
    mov byte [es:di+2], al
    mov byte [es:di+3], al

    inc si
    dec cx
    jnz df_snake

    call draw_hud_bar
    ret

; ============================================================
;  NOURRITURE
; ============================================================
draw_food_blk:
    mov ax, 0A000h
    mov es, ax

    xor ah, ah
    mov al, byte [food_x]
    mov bx, BSIZE
    mul bx
    add ax, OFS_X
    mov bx, ax

    xor ah, ah
    mov al, byte [food_y]
    push bx
    mov bx, BSIZE
    mul bx
    add ax, OFS_Y
    pop bx

    push bx
    mov bx, 320
    mul bx
    pop bx
    add ax, bx
    mov di, ax
    mov al, C_FOOD

    mov byte [es:di],   al
    mov byte [es:di+1], al
    mov byte [es:di+2], al
    mov byte [es:di+3], al
    add di, 320
    mov byte [es:di],   al
    mov byte [es:di+1], al
    mov byte [es:di+2], al
    mov byte [es:di+3], al
    add di, 320
    mov byte [es:di],   al
    mov byte [es:di+1], al
    mov byte [es:di+2], al
    mov byte [es:di+3], al
    add di, 320
    mov byte [es:di],   al
    mov byte [es:di+1], al
    mov byte [es:di+2], al
    mov byte [es:di+3], al
    ret

; ============================================================
;  HUD - barre de score
; ============================================================
draw_hud_bar:
    mov ax, 0A000h
    mov es, ax

    xor di, di
    mov cx, OFS_Y * 320
    mov al, C_HUD
    rep stosb

    mov ax, word [score]
    shr ax, 1
    cmp ax, 300
    jbe hud_ok
    mov ax, 300
hud_ok:
    mov bx, ax
    test bx, bx
    jz  hud_end
    mov dx, 2
hud_row:
    push dx
    xor ah, ah
    mov ax, dx
    mov cx, 320
    mul cx
    add ax, 5
    mov di, ax
    mov cx, bx
    mov al, C_BODY
    rep stosb
    pop dx
    inc dx
    cmp dx, 13
    jle hud_row
hud_end:
    ret

; ============================================================
;  TERRAIN (bordure) - appele une seule fois
; ============================================================
draw_terrain:
    mov ax, 0A000h
    mov es, ax

    xor di, di
    mov cx, 64000
    xor al, al
    rep stosb

    ; Ligne haute (y = OFS_Y - 1 = 15)
    mov di, 15 * 320
    mov cx, 320
    mov al, C_BORDER
    rep stosb

    ; Ligne basse
    mov di, (OFS_Y + (MAX_Y+1)*BSIZE) * 320
    mov cx, 320
    mov al, C_BORDER
    rep stosb

    ; Colonnes gauche et droite
    mov dx, OFS_Y
dt_col:
    push dx
    xor ah, ah
    mov ax, dx
    mov bx, 320
    mul bx
    mov di, ax
    mov byte [es:di + OFS_X - 1],                    C_BORDER
    mov byte [es:di + OFS_X + (MAX_X+1)*BSIZE],      C_BORDER
    pop dx
    inc dx
    cmp dx, OFS_Y + (MAX_Y+1)*BSIZE
    jle dt_col
    ret

; ============================================================
;  GAME OVER
; ============================================================
game_over:
    mov ax, 0003h
    int 10h

    mov ah, 02h
    xor bh, bh
    mov dh, 11
    mov dl, 10
    int 10h

    mov ah, 09h
    mov dx, msg_over
    int 21h

    call show_score

    mov ah, 09h
    mov dx, msg_again
    int 21h

go_loop:
    mov ah, 00h
    int 16h
    cmp al, 1Bh
    je  exit_prog
    cmp al, 'r'
    je  go_restart
    cmp al, 'R'
    je  go_restart
    jmp go_loop

go_restart:
    call init_vars
    mov ax, 0013h
    int 10h
    call draw_terrain
    jmp main_loop

; ============================================================
;  AFFICHAGE SCORE
; ============================================================
show_score:
    mov ax, word [score]
    xor dx, dx
    mov bx, 10000
    div bx
    add al, '0'
    mov [score_buf+0], al
    mov ax, dx
    xor dx, dx
    mov bx, 1000
    div bx
    add al, '0'
    mov [score_buf+1], al
    mov ax, dx
    xor dx, dx
    mov bx, 100
    div bx
    add al, '0'
    mov [score_buf+2], al
    mov ax, dx
    xor dx, dx
    mov bx, 10
    div bx
    add al, '0'
    mov [score_buf+3], al
    add dl, '0'
    mov [score_buf+4], dl
    mov ah, 09h
    mov dx, score_buf
    int 21h
    ret

; ============================================================
;  PLACEMENT NOURRITURE (LCG)
; ============================================================
place_food:
    mov ax, word [rnd_seed]
    mov bx, 25173
    mul bx
    add ax, 13849
    mov word [rnd_seed], ax
    xor dx, dx
    mov bx, MAX_X
    div bx
    mov byte [food_x], dl

    mov ax, word [rnd_seed]
    mov bx, 25173
    mul bx
    add ax, 13849
    mov word [rnd_seed], ax
    xor dx, dx
    mov bx, MAX_Y
    div bx
    mov byte [food_y], dl
    ret

; ============================================================
;  TEMPORISATION
; ============================================================
wait_delay:
    push cx
    push bx
    mov bx, 6
wd_out:
    mov cx, 0FFFFh
wd_in:
    loop wd_in
    dec bx
    jnz wd_out
    pop bx
    pop cx
    ret