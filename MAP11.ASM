        .386p
code    segment public use32
        assume cs:code,ds:code

        include map00.h
        include empty.h
        include file.h
        include ppu.h
        include data.h
        include equates.h
include 6502.h
        public mapperinit11
;----------------------------------------------------------------------------
mapperinit11:;
;----------------------------------------------------------------------------
        xor al,al
        call map89ABCDEF
        call flush

        mov eax,offset w8000__          ;redirect rom writes
        mov [write_tbl+4*4],eax
        mov eax,offset w8000
        mov [write_tbl+5*4],eax
        mov [write_tbl+6*4],eax
        mov [write_tbl+7*4],eax

        test [cartflags],MIRROR
        call mirror2H

        ret
;----------------------------------------------------------------------------
w8000__:;       shoddy hack for DeathRace
;----------------------------------------------------------------------------
        cmp edi,8000h
        jne w8000
        ret
;----------------------------------------------------------------------------
w8000:
;----------------------------------------------------------------------------
        push eax                        ;set 32k of ROM
        call map89ABCDEF
        pop eax

        and eax,0f0h
        shl eax,11
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

        jmp flush
;----------------------------------------------------------------------------
code    ends
        end
