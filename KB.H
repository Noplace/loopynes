extrn   kb_init:near
extrn   kb_clear:near
extrn   getch:near
extrn   kb_last:byte
extrn   kb_flags:byte

kbtest macro key
        test [kb_table+key],0ffh
endm

getc macro
        mov al,[kb_last]
        mov [kb_last],0
        or al,al
endm
