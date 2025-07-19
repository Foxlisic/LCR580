; Переменные
; ------------------------------------------------------------------------------
color:      defb    $00
curxy:      defw    $0000

; Чистка экрана от мусора
; ------------------------------------------------------------------------------

cls:        ld      b, a
            ld      (color), a
            rrca
            rrca
            rrca
            rrca
            out     ($FE), a
            ld      a, b
            ld      hl, $5800
            ld      bc, $0003
            call    stosb
            xor     a
            ld      c, $18
            ld      h, $40
            call    stosb
            ret

; Отгрузка значения A, начиная с HL, количество отгрузок B+256*C (Если B=0)
; ------------------------------------------------------------------------------

stosb:      ld      (hl), a
            inc     hl
            djnz    stosb
            dec     c
            jr      nz, stosb
            ret

; Печать символа A в позиции H=Y,L=X
; ------------------------------------------------------------------------------

pchar:      push    hl
            push    de
            push    bc
            push    hl
            ex      de, hl              ; Сохранить HL в DE
            sub     a, $20              ; Сместить ASCII
            jr      nc, pchar_L1
            xor     a
pchar_L1:   call    calchra
            ex      de, hl              ; Восстановить HL
            ld      bc, $4000
            add     hl, bc
            ld      b, 8
pchar_L0:   ld      a, (de)
            ld      (hl), a
            inc     de
            ld      a, l
            add     $20
            ld      l, a
            djnz    pchar_L0
            pop     hl
            call    attra
            ld      a, (color)
            ld      (hl), a             ; Обновление атрибута
            pop     bc
            pop     de
            pop     hl
            ret

; HL = zxfont + 8*A Вычислить адрес знакоместа по A [0..n]
; ------------------------------------------------------------------------------
calchra:    ld      h, 0
            ld      l, a
            ld      bc, zxfont
            add     hl, hl
            add     hl, hl
            add     hl, hl
            add     hl, bc
            ret

; HL = $5800 + H*32 + L Вычисление адреса атрибута
; ------------------------------------------------------------------------------
attra:      ld      c, l
            ld      b, 0x58             ; Установка атрибута
            ld      l, h
            ld      h, 0
            add     hl, hl
            add     hl, hl
            add     hl, hl
            add     hl, hl
            add     hl, hl
            add     hl, bc              ; HL=0x5800 + 32*Y + C
            ret

; Пропечать A в режиме телетайпа (HL)
; ------------------------------------------------------------------------------
tchar:      call    pchar
            inc     l
            ld      a, l
            and     $1F
            jr      nz, tchar_e
            ld      l, a
            inc     h
            ; h >= 24
tchar_e:    ld      (curxy), hl
            ret

; Пропечатка DE-строки в H=Y,L=X
; ------------------------------------------------------------------------------

pstr:       ld      a, (de)
            inc     de
            and     a
            ret     z
            call    tchar
            jr      pstr

; Обновление символа ZXFont из DE -> A
; ------------------------------------------------------------------------------
upsym:      push    af
            push    bc
            push    hl
            sub     a, $20
            call    calchra
            ld      b, 8
upsym1:     ld      a, (de)
            ld      (hl), a
            inc     de
            inc     hl
            djnz    upsym1
            pop     hl
            pop     bc
            pop     af
            ret
