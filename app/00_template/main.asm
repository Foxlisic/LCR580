            jr      boot
; ------------------------------------------------------------------------------
defw        iKeyb                   ; IRQ#1 KEYBOARD
defw        iRetrace                ; IRQ#2 VRETRACE
defw        $0000                   ; IRQ#3 TIMER
; ------------------------------------------------------------------------------
boot:       ld      sp, $8000
            ld      a, $07
            call    cls
            ld      hl, $1705
            ld      de, s1
L1:         ld      a, (de)
            inc     de
            and     a
            jr      z, L2
            call    pchar
            inc     l
            jr      L1
L2:         ld      hl, $0000
            ei

            halt
s1:         defb    "For your consideration",0

; For YC?
iKeyb:      in      a, ($FE)
            call    pchar
            inc     l
            reti
iRetrace:   reti

; ------------------------------------------------------------------------------
include     "../lib/zx2/stdlib.asm"
include     "../lib/zx1/font.asm"
