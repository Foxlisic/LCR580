
            ld      sp, $8000
            ld      a,  $01
            out     ($fe), a

            ; Заполнить атрибутикой
            ld      hl, $5800
            ld      a,  8*$01 + $07
            ld      bc, $0003
aa:         ld      (hl), a
            inc     hl
            djnz    aa
            dec     c
            jr      nz, aa
            ld      hl, $4000

            ; Заполнить мусором
            ld      bc, $0008
ab:         ld      (hl), $55
            inc     hl
            ld      (hl), $AA
            inc     hl
            ld      (hl), $11
            inc     hl

            djnz    ab
            dec     c
            jr      nz, ab

            halt
