        .386p
code    segment public use32
        assume cs:code,ds:code

        include map00.h
        include empty.h
        include file.h
        include ppu.h
        include data.h
        include equates.h
        include debug.h
        include kb.h

        public mapperinit03
;----------------------------------------------------------------------------
mapperinit03:;
;----------------------------------------------------------------------------
        xor al,al
        call map89AB
        mov al,-1
        call mapCDEF
        call flush

        mov eax,offset write0           ;redirect rom writes to mapper
        mov [write_tbl+4*4],eax
        mov [write_tbl+5*4],eax
        mov [write_tbl+6*4],eax
        mov [write_tbl+7*4],eax

        test [cartflags],MIRROR         ;set mirror
        call mirror2H

        ret
;----------------------------------------------------------------------------
write0:
;----------------------------------------------------------------------------
        trace tMMC0,al
        shl eax,15
        and eax,[chrmask]
        add eax,[chr_ptr]

        mov [chr_map],eax               ;map chr ($0000-1fff)
        add eax,1000h
        mov [chr_map+4],eax
        add eax,1000h
        mov [chr_map+8],eax
        add eax,1000h
        mov [chr_map+12],eax
        add eax,1000h
        mov [chr_map+16],eax
        add eax,1000h
        mov [chr_map+20],eax
        add eax,1000h
        mov [chr_map+24],eax
        add eax,1000h
        mov [chr_map+28],eax
        call newchrmap
        ret
;----------------------------------------------------------------------------
code    ends
        end
