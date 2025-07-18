; Переменные
; ------------------------------------------------------------------------------
curcl:      defb    $00
curxy:      defw    $0000

; Чистка экрана от мусора
; ------------------------------------------------------------------------------

cls:        ld      b, a
            ld      (curcl), a
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

pchr:       push    hl
            push    de
            push    bc
            push    hl
            ex      de, hl              ; Сохранить HL в DE
            sub     a, $20              ; Сместить ASCII
            jr      nc, pchar_L1
            xor     a
pchar_L1:   ld      h, 0
            ld      l, a
            ld      bc, zxfont
            add     hl, hl
            add     hl, hl
            add     hl, hl
            add     hl, bc              ; DE=zxfont+8*(a-20h)
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
            ld      b, 0x58             ; Установка атрибута
            ld      c, l
            ld      l, h
            ld      h, 0
            add     hl, hl
            add     hl, hl
            add     hl, hl
            add     hl, hl
            add     hl, hl
            add     hl, bc              ; HL=0x5800 + 32*Y + C
            ld      a, (curcl)
            ld      (hl), a             ; Обновление атрибута
            pop     bc
            pop     de
            pop     hl
            ret

; Пропечать A в режиме телетайпа (HL)
; ------------------------------------------------------------------------------
tchar:      call    pchr
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
