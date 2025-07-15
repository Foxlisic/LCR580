
            ld      sp, $A000

            ld      a, $07
            call    cls

            ld      hl, $0000
            ld      de, s1
L1:         ld      a, (de)
            inc     de
            and     a
            jr      z, end
            call    pchar
            inc     l
            jr      L1

end:
            halt

s1:         defb    "Hello World!",0

include     "../lib/zx2/stdlib.asm"
include     "../lib/zx1/font.asm"
