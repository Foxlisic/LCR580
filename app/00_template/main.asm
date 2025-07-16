
            ld      sp, $8000

            ld      a, $07
            call    cls

            ;ld      hl, $0B0B
            ld      hl, $1705
            ld      de, s1
L1:         ld      a, (de)
            inc     de
            and     a
            jr      z, L2
            call    pchar
            inc     l
            jr      L1

L2:         in      a, ($FE)
            ld      hl, $0000
            call    pchar
            jr      L2

            halt

;s1:         defb    "Minus Odin",0
s1:         defb    "For your consideration",0

include     "../lib/zx2/stdlib.asm"
include     "../lib/zx1/font.asm"
