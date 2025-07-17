            jr      boot
; ------------------------------------------------------------------------------
defw        iKeyb                   ; IRQ#1
defw        $0000                   ; IRQ#2
defw        $0000                   ; IRQ#3
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
L2:         ei
            ld      hl, $0000
            halt

s1:         defb    "For your consideration",0

; For YC?
iKeyb:      in      a, ($FE)
            call    pchar
            inc     l
            reti

; ------------------------------------------------------------------------------
include     "../lib/zx2/stdlib.asm"
include     "../lib/zx1/font.asm"
