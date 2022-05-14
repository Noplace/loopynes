        .386p
code    segment public use32
        assume cs:code,ds:code

        include debug.h
        include empty.h
        include file.h
        include ppu.h
        include data.h
        include equates.h
        include map00.h
        include kb.h
include main.h
        public mapperinit07
;----------------------------------------------------------------------------
mapperinit07:;
;----------------------------------------------------------------------------
        xor al,al
        call map89ABCDEF
        call flush

        mov eax,offset write0           ;redirect rom writes to mapper
        mov [write_tbl+4*4],eax
        mov [write_tbl+5*4],eax
        mov [write_tbl+6*4],eax
        mov [write_tbl+7*4],eax

        xor eax,eax                     ;set mirror
        call mirror1

        ret
;----------------------------------------------------------------------------
write0:
;----------------------------------------------------------------------------
        trace tMMC0,al
        test al,10h                     ;set mirror
        call mirror1

        call map89ABCDEF                ;map rom bank
        jmp flush
;----------------------------------------------------------------------------
code    ends
        end
