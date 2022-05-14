        .386p
code    segment public use32
        assume cs:code,ds:code

        include map00.h
        include empty.h
        include file.h
        include ppu.h
        include data.h
        include equates.h

        public mapperinit02
;----------------------------------------------------------------------------
mapperinit02:;
;----------------------------------------------------------------------------
        xor al,al
        call map89AB
        mov al,-1
        call mapCDEF
        call flush

        mov eax,offset w8000            ;redirect rom writes
        mov [write_tbl+4*4],eax
        mov [write_tbl+5*4],eax
        mov [write_tbl+6*4],eax
        mov [write_tbl+7*4],eax

        test [cartflags],MIRROR         ;set mirror
        call mirror2H

        call pal_init                   ;check VS castlevania palette
        ret
;----------------------------------------------------------------------------
w8000:
;----------------------------------------------------------------------------
        call map89AB
        jmp flush
;----------------------------------------------------------------------------
code    ends
        end
