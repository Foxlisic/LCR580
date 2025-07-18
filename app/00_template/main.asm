            jr      boot
; ------------------------------------------------------------------------------
defw        iKeyb                   ; IRQ#1 KEYBOARD
defw        iRetrace                ; IRQ#2 VRETRACE
; ------------------------------------------------------------------------------
boot:       ld      sp, $8000
            ld      a, $07
            call    cls

            ld      a, 0x30
            ld      (curcl), a

            ld      hl, $0000
            ld      de, s1
            call    pstr

            halt
s1:         defb    "X-Tension Cosmic Space Game 2025",0

; For YC?
iKeyb:      in      a, ($FE)
            call    pchr
            inc     l
            reti
iRetrace:   reti

; ------------------------------------------------------------------------------
include     "../lib/zx/stdlib.asm"
include     "../lib/zx/font.asm"
