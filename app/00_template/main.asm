            jr      boot
; ------------------------------------------------------------------------------
defw        iKeyb                   ; IRQ#1 KEYBOARD
defw        iRetrace                ; IRQ#2 VRETRACE
; ------------------------------------------------------------------------------
boot:       ld      sp, $8000
            ld      a, $07
            call    cls

            ld      a, 8*3 + 0
            ld      (curcl), a

            ld      hl, $0000
            ld      de, s1
            call    pstr


            halt
s1:         defb    "For your consideration For Your Monoment Monumentos",0

; For YC?
iKeyb:      in      a, ($FE)
            call    pchar
            inc     l
            reti
iRetrace:   reti

; ------------------------------------------------------------------------------
include     "../lib/zx/stdlib.asm"
include     "../lib/zx/font.asm"
