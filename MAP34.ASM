        .386p
code    segment public use32
        assume cs:code,ds:code

        include 6502.h
        include map00.h
        include empty.h
        include file.h
        include ppu.h
        include data.h
        include equates.h
        include memory.h

        public mapperinit34
;----------------------------------------------------------------------------
mapperinit34:;
;----------------------------------------------------------------------------
        xor al,al
        call map89ABCDEF
        call flush

        test [cartflags],MIRROR
        call mirror2H

        mov [write_tbl+3*4],offset write0
        mov [write_tbl+4*4],offset write1
        mov [write_tbl+5*4],offset write1
        mov [write_tbl+6*4],offset write1
        mov [write_tbl+7*4],offset write1

        ret
;----------------------------------------------------------------------------
write0:
;----------------------------------------------------------------------------
        push eax
        call sram_W
        pop eax

        cmp edi,7ffdh
        je write1

        cmp edi,7ffeh
        jne w1
        shl eax,14
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map],eax
        add eax,1000h
        mov [chr_map+4],eax
        add eax,1000h
        mov [chr_map+8],eax
        add eax,1000h
        mov [chr_map+12],eax
        jmp newchrmap
w1:
        cmp edi,7fffh
        jne w2

        shl eax,14
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+16],eax
        add eax,1000h
        mov [chr_map+20],eax
        add eax,1000h
        mov [chr_map+24],eax
        add eax,1000h
        mov [chr_map+28],eax
        jmp newchrmap
w2:
        ret
;----------------------------------------------------------------------------
write1:
;----------------------------------------------------------------------------
        call map89ABCDEF
        jmp flush
;----------------------------------------------------------------------------
code    ends
        end
